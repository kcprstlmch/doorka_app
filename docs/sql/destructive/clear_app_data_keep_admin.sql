-- DESTRUCTIVE manual cleanup for Doorka test data.
-- Do not run this as part of normal Supabase changes.
-- Run this by hand in Supabase SQL Editor only after explicit confirmation.
-- It deletes app data and keeps the profile for kcprstlmch@gmail.com.
-- It does not automatically delete users from auth.users.

-- Auth/profile trigger fix.
-- Run this section if signup fails with:
-- "Database error saving new user" or "error adding new user".
-- Registration stays minimal: email + password only.

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  role text not null default 'agent',
  full_name text,
  phone text,
  avatar_path text,
  auto_record_meetings boolean not null default true,
  default_daily_goal int not null default 9
);

alter table public.profiles
  add column if not exists email text,
  add column if not exists role text not null default 'agent',
  add column if not exists full_name text,
  add column if not exists phone text,
  add column if not exists avatar_path text,
  add column if not exists auto_record_meetings boolean not null default true,
  add column if not exists default_daily_goal int not null default 9;

update public.profiles
set
  email = coalesce(
    public.profiles.email,
    (
      select auth.users.email
      from auth.users
      where auth.users.id = public.profiles.id
      limit 1
    ),
    'unknown-' || public.profiles.id::text || '@doorka.local'
  ),
  role = coalesce(public.profiles.role, 'agent');

alter table public.profiles
  alter column email set not null,
  alter column role set default 'agent',
  alter column role set not null;

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('agent', 'admin', 'moderator'));

do $do$
declare
  trigger_name text;
begin
  for trigger_name in
    select tgname
    from pg_trigger
    where tgrelid = 'auth.users'::regclass
      and not tgisinternal
  loop
    execute format('drop trigger if exists %I on auth.users', trigger_name);
  end loop;
end
$do$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (
    id,
    email,
    role,
    full_name
  )
  values (
    new.id,
    new.email,
    case
      when lower(new.email) = 'kcprstlmch@gmail.com' then 'admin'
      else 'agent'
    end,
    coalesce(
      new.raw_user_meta_data->>'full_name',
      split_part(new.email, '@', 1)
    )
  )
  on conflict (id) do update
  set
    email = excluded.email,
    full_name = coalesce(public.profiles.full_name, excluded.full_name),
    role = case
      when lower(excluded.email) = 'kcprstlmch@gmail.com' then 'admin'
      else public.profiles.role
    end;

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

begin;

delete from public.contact_events;
delete from public.work_cycles;
delete from public.lead_sessions;
delete from public.clients;
delete from public.contacts;

delete from public.profiles
where lower(email) <> 'kcprstlmch@gmail.com';

commit;

-- Optional, only if you also want to remove other Auth users.
-- Use this only after confirming in Supabase Auth that these accounts should disappear.
--
-- begin;
-- delete from auth.users
-- where lower(email) <> 'kcprstlmch@gmail.com';
-- commit;
