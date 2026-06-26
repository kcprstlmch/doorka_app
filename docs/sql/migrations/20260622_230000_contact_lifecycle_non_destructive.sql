-- Doorka contact lifecycle model.
-- Safe migration: adds the new Kontakt -> Umowione spotkanie -> Do realizacji structure
-- without deleting existing contacts, meetings or clients.
-- Run manually in Supabase SQL Editor.

begin;

create extension if not exists pgcrypto;

alter table public.contacts
  add column if not exists contact_type text,
  add column if not exists contact_status text,
  add column if not exists lifecycle_stage text not null default 'contact';

alter table public.contacts
  drop constraint if exists contacts_lifecycle_stage_check;

alter table public.contacts
  add constraint contacts_lifecycle_stage_check
  check (lifecycle_stage in ('contact', 'meeting', 'in_progress'));

-- `contacts.status` zostaje jako pole kompatybilnosci ze stara aplikacja.
-- Nowe statusy kontaktow sa elastyczne i trafiaja do `contact_status`.
alter table public.contacts
  drop constraint if exists contacts_status_check;

update public.contacts
set lifecycle_stage = case
  when moved_to_client_at is not null or status = 'signed_contract' then 'in_progress'
  when status in ('scheduled_meeting', 'meeting_active', 'meeting_done', 'postponed', 'not_interested')
    or contact_date is not null
    or meeting_time is not null
    then 'meeting'
  else 'contact'
end
where lifecycle_stage is null or lifecycle_stage = 'contact';

update public.contacts
set contact_status = case
  when contact_status is not null then contact_status
  else contact_status
end;

update public.contacts
set contact_type = contact_quality
where contact_type is null
  and contact_quality is not null
  and contact_quality not in ('S', 'M', 'L', 'XL');

create table if not exists public.contact_status_options (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('type', 'status')),
  label text not null,
  color text not null default '#8A8F98',
  sort_order int not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists contact_status_options_agent_kind_label_idx
on public.contact_status_options(agent_id, kind, lower(label));

create index if not exists contact_status_options_agent_kind_idx
on public.contact_status_options(agent_id, kind, is_active, sort_order);

create table if not exists public.contact_type_assignments (
  contact_id uuid not null references public.contacts(id) on delete cascade,
  type_id uuid not null references public.contact_status_options(id) on delete cascade,
  agent_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (contact_id, type_id)
);

create index if not exists contact_type_assignments_contact_id_idx
on public.contact_type_assignments(contact_id);

create index if not exists contact_type_assignments_agent_id_idx
on public.contact_type_assignments(agent_id);

create or replace function public.enforce_contact_type_assignments_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if (
    select count(*)
    from public.contact_type_assignments existing
    where existing.contact_id = new.contact_id
      and existing.type_id <> new.type_id
  ) >= 3 then
    raise exception 'Kontakt moze miec maksymalnie 3 aktywne typy';
  end if;

  return new;
end;
$$;

drop trigger if exists contact_type_assignments_limit_trigger on public.contact_type_assignments;

create trigger contact_type_assignments_limit_trigger
before insert or update on public.contact_type_assignments
for each row execute function public.enforce_contact_type_assignments_limit();

insert into public.contact_status_options (
  agent_id,
  kind,
  label,
  color,
  sort_order
)
select distinct
  contact.agent_id,
  'type',
  contact.contact_type,
  '#8A8F98',
  0
from public.contacts contact
where contact.agent_id is not null
  and contact.contact_type is not null
  and btrim(contact.contact_type) <> ''
on conflict (agent_id, kind, lower(label)) do nothing;

insert into public.contact_type_assignments (
  contact_id,
  type_id,
  agent_id
)
select
  contact.id,
  option.id,
  contact.agent_id
from public.contacts contact
join public.contact_status_options option
  on option.agent_id = contact.agent_id
  and option.kind = 'type'
  and lower(option.label) = lower(contact.contact_type)
where contact.agent_id is not null
  and contact.contact_type is not null
  and btrim(contact.contact_type) <> ''
on conflict (contact_id, type_id) do nothing;

create or replace function public.enforce_contact_status_options_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if new.is_active and (
    select count(*)
    from public.contact_status_options existing
    where existing.agent_id = new.agent_id
      and existing.kind = new.kind
      and existing.is_active
      and existing.id <> new.id
  ) >= 10 then
    raise exception 'Limit 10 aktywnych typow/statusow zostal osiagniety';
  end if;

  return new;
end;
$$;

drop trigger if exists contact_status_options_limit_trigger on public.contact_status_options;

create trigger contact_status_options_limit_trigger
before insert or update on public.contact_status_options
for each row execute function public.enforce_contact_status_options_limit();

create table if not exists public.meetings (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references auth.users(id) on delete cascade,
  source_contact_id uuid references public.contacts(id) on delete set null,
  contact_name text,
  phone text,
  address text,
  meeting_date date,
  meeting_time time,
  quality text,
  note text,
  result text,
  result_reason text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.meetings
  drop constraint if exists meetings_result_check;

alter table public.meetings
  add constraint meetings_result_check
  check (
    result is null
    or result in ('sold', 'not_sold', 'postponed', 'not_interested')
  );

create unique index if not exists meetings_source_contact_id_unique_idx
on public.meetings(source_contact_id);

create index if not exists meetings_agent_id_idx on public.meetings(agent_id);
create index if not exists meetings_meeting_date_idx on public.meetings(meeting_date);
create index if not exists meetings_archived_at_idx on public.meetings(archived_at);
create index if not exists contacts_agent_lifecycle_stage_idx on public.contacts(agent_id, lifecycle_stage);
create index if not exists contacts_contact_type_idx on public.contacts(contact_type);
create index if not exists contacts_contact_status_idx on public.contacts(contact_status);

insert into public.meetings (
  agent_id,
  source_contact_id,
  contact_name,
  phone,
  address,
  meeting_date,
  meeting_time,
  quality,
  note,
  result,
  result_reason,
  archived_at,
  created_at,
  updated_at
)
select
  contact.agent_id,
  contact.id,
  contact.contact_name,
  contact.phone,
  contact.address,
  contact.contact_date,
  contact.meeting_time,
  contact.contact_quality,
  contact.note,
  case
    when contact.meeting_result = 'signed_contract' then 'sold'
    when contact.meeting_result = 'postponed' or contact.status = 'postponed' then 'postponed'
    when contact.meeting_result = 'not_interested' or contact.status = 'not_interested' then 'not_interested'
    when contact.meeting_result = 'missed' or contact.status in ('meeting_done', 'no_contact') then 'not_sold'
    else null
  end,
  contact.not_interested_reason,
  contact.archived_at,
  contact.created_at,
  contact.updated_at
from public.contacts contact
where contact.agent_id is not null
  and (
    contact.lifecycle_stage = 'meeting'
    or contact.status in ('scheduled_meeting', 'meeting_active', 'meeting_done', 'postponed', 'not_interested')
    or contact.contact_date is not null
    or contact.meeting_time is not null
  )
on conflict (source_contact_id) do update
set
  agent_id = excluded.agent_id,
  contact_name = excluded.contact_name,
  phone = excluded.phone,
  address = excluded.address,
  meeting_date = excluded.meeting_date,
  meeting_time = excluded.meeting_time,
  quality = excluded.quality,
  note = excluded.note,
  result = excluded.result,
  result_reason = excluded.result_reason,
  archived_at = excluded.archived_at,
  updated_at = now();

alter table public.clients
  add column if not exists source_meeting_id uuid references public.meetings(id) on delete set null;

create index if not exists clients_source_meeting_id_idx on public.clients(source_meeting_id);

alter table public.contact_status_options enable row level security;
alter table public.contact_type_assignments enable row level security;
alter table public.meetings enable row level security;

drop policy if exists "Contact options are readable by owner" on public.contact_status_options;
create policy "Contact options are readable by owner"
on public.contact_status_options for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contact options are insertable by owner" on public.contact_status_options;
create policy "Contact options are insertable by owner"
on public.contact_status_options for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Contact options are editable by owner" on public.contact_status_options;
create policy "Contact options are editable by owner"
on public.contact_status_options for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Contact options are deletable by owner" on public.contact_status_options;
create policy "Contact options are deletable by owner"
on public.contact_status_options for delete to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contact type assignments are readable by owner" on public.contact_type_assignments;
create policy "Contact type assignments are readable by owner"
on public.contact_type_assignments for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contact type assignments are insertable by owner" on public.contact_type_assignments;
create policy "Contact type assignments are insertable by owner"
on public.contact_type_assignments for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Contact type assignments are editable by owner" on public.contact_type_assignments;
create policy "Contact type assignments are editable by owner"
on public.contact_type_assignments for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Contact type assignments are deletable by owner" on public.contact_type_assignments;
create policy "Contact type assignments are deletable by owner"
on public.contact_type_assignments for delete to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Meetings are readable by owner" on public.meetings;
create policy "Meetings are readable by owner"
on public.meetings for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Meetings are insertable by owner" on public.meetings;
create policy "Meetings are insertable by owner"
on public.meetings for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Meetings are editable by owner" on public.meetings;
create policy "Meetings are editable by owner"
on public.meetings for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Meetings are deletable by owner" on public.meetings;
create policy "Meetings are deletable by owner"
on public.meetings for delete to authenticated
using (auth.uid() = agent_id);

commit;
