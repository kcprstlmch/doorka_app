# SQL

Ten plik zawiera aktualny roboczy SQL do ręcznego uruchomienia w Supabase SQL Editor.
Nic z tego pliku nie wykonuje się automatycznie.

## Etap 1.2 - Contact Mechanics

Ten SQL przygotowuje bazę pod mechanikę kontaktów 1.2.
Zakłada świadomy reset danych roboczych w `contacts`, `clients`, `lead_sessions`, `work_cycles` i `contact_events`.
Nie usuwa użytkowników z `auth.users` ani profili.

Przed uruchomieniem:
- upewnij się, że masz aktualny commit,
- zaakceptuj utratę obecnych kontaktów i klientów testowych,
- uruchamiaj ręcznie w Supabase SQL Editor.

```sql
begin;

create extension if not exists pgcrypto;

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
  add column if not exists auto_record_meetings boolean not null default true,
  add column if not exists default_daily_goal int not null default 9;

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid()
);

alter table public.contacts
  add column if not exists agent_id uuid references auth.users(id) on delete cascade,
  add column if not exists contact_name text,
  add column if not exists phone text,
  add column if not exists address text,
  add column if not exists status text not null default 'scheduled_meeting',
  add column if not exists note text,
  add column if not exists contact_date date,
  add column if not exists contact_time time,
  add column if not exists meeting_time time,
  add column if not exists contact_quality text,
  add column if not exists contact_notification timestamptz,
  add column if not exists meeting_started_at timestamptz,
  add column if not exists meeting_finished_at timestamptz,
  add column if not exists meeting_result text,
  add column if not exists not_interested_reason text,
  add column if not exists local_recording_path text,
  add column if not exists ai_summary text,
  add column if not exists ai_analysis text,
  add column if not exists archived_at timestamptz,
  add column if not exists moved_to_client_at timestamptz,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_at timestamptz not null default now();

alter table public.contacts
  drop column if exists contact_product;

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid()
);

alter table public.clients
  add column if not exists agent_id uuid references auth.users(id) on delete cascade,
  add column if not exists source_contact_id uuid references public.contacts(id) on delete set null,
  add column if not exists client_name text,
  add column if not exists phone text,
  add column if not exists correspondence_address text,
  add column if not exists installation_address text,
  add column if not exists product_name text,
  add column if not exists contract_signed_at date,
  add column if not exists gross_amount numeric(12,2),
  add column if not exists client_process_note text,
  add column if not exists status text not null default 'signed_contract',
  add column if not exists execution_method text,
  add column if not exists archived_at timestamptz;

create table if not exists public.lead_sessions (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references auth.users(id) on delete cascade,
  session_date date not null,
  scheduled_meetings_count int not null default 0,
  collected_contacts_count int not null default 0,
  work_seconds int not null default 0,
  break_seconds int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.work_cycles (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references auth.users(id) on delete cascade,
  lead_date date,
  sales_date date,
  status text not null default 'open',
  scheduled_count int not null default 0,
  leads_count int not null default 0,
  completed_meetings_count int not null default 0,
  postponed_count int not null default 0,
  missed_count int not null default 0,
  signed_contracts_count int not null default 0,
  closed_at timestamptz,
  created_at timestamptz not null default now()
);

create table if not exists public.contact_events (
  id uuid primary key default gen_random_uuid(),
  agent_id uuid not null references auth.users(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete cascade,
  work_cycle_id uuid references public.work_cycles(id) on delete set null,
  event_type text not null,
  event_note text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.contacts drop constraint if exists contacts_status_check;
alter table public.contacts
  add constraint contacts_status_check
  check (status in (
    'scheduled_meeting',
    'meeting_active',
    'meeting_done',
    'signed_contract',
    'interested',
    'contact',
    'postponed',
    'not_interested',
    'no_contact'
  ));

alter table public.contacts drop constraint if exists contacts_meeting_result_check;
alter table public.contacts
  add constraint contacts_meeting_result_check
  check (
    meeting_result is null
    or meeting_result in (
      'signed_contract',
      'interested',
      'not_interested',
      'missed',
      'postponed'
    )
  );

alter table public.work_cycles drop constraint if exists work_cycles_status_check;
alter table public.work_cycles
  add constraint work_cycles_status_check
  check (status in ('open', 'closed'));

truncate table public.contact_events restart identity cascade;
truncate table public.work_cycles restart identity cascade;
truncate table public.lead_sessions restart identity cascade;
truncate table public.clients restart identity cascade;
truncate table public.contacts restart identity cascade;

create index if not exists contacts_agent_id_idx on public.contacts(agent_id);
create index if not exists contacts_status_idx on public.contacts(status);
create index if not exists contacts_contact_date_idx on public.contacts(contact_date);
create index if not exists contacts_contact_notification_idx on public.contacts(contact_notification);
create index if not exists work_cycles_agent_id_idx on public.work_cycles(agent_id);
create index if not exists contact_events_contact_id_idx on public.contact_events(contact_id);

alter table public.contacts enable row level security;
alter table public.clients enable row level security;
alter table public.lead_sessions enable row level security;
alter table public.work_cycles enable row level security;
alter table public.contact_events enable row level security;

drop policy if exists "Contacts are readable by owner" on public.contacts;
create policy "Contacts are readable by owner"
on public.contacts for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contacts are insertable by owner" on public.contacts;
create policy "Contacts are insertable by owner"
on public.contacts for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Contacts are editable by owner" on public.contacts;
create policy "Contacts are editable by owner"
on public.contacts for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Contacts are deletable by owner" on public.contacts;
create policy "Contacts are deletable by owner"
on public.contacts for delete to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Work cycles are readable by owner" on public.work_cycles;
create policy "Work cycles are readable by owner"
on public.work_cycles for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Work cycles are insertable by owner" on public.work_cycles;
create policy "Work cycles are insertable by owner"
on public.work_cycles for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Work cycles are editable by owner" on public.work_cycles;
create policy "Work cycles are editable by owner"
on public.work_cycles for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Contact events are readable by owner" on public.contact_events;
create policy "Contact events are readable by owner"
on public.contact_events for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contact events are insertable by owner" on public.contact_events;
create policy "Contact events are insertable by owner"
on public.contact_events for insert to authenticated
with check (auth.uid() = agent_id);

commit;
```

### Hotfix po Etapie 1.2 - RLS dla `clients` i `lead_sessions`

Jeśli Etap 1.2 został już uruchomiony, odpal jeszcze ten blok.
Dodaje brakujące polityki RLS dla tabel używanych przez aplikację po resecie.

```sql
begin;

alter table public.clients enable row level security;
alter table public.lead_sessions enable row level security;
alter table public.profiles enable row level security;

drop policy if exists "Clients are readable by owner" on public.clients;
create policy "Clients are readable by owner"
on public.clients for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Clients are insertable by owner" on public.clients;
create policy "Clients are insertable by owner"
on public.clients for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Clients are editable by owner" on public.clients;
create policy "Clients are editable by owner"
on public.clients for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Clients are deletable by owner" on public.clients;
create policy "Clients are deletable by owner"
on public.clients for delete to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Lead sessions are readable by owner" on public.lead_sessions;
create policy "Lead sessions are readable by owner"
on public.lead_sessions for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Lead sessions are insertable by owner" on public.lead_sessions;
create policy "Lead sessions are insertable by owner"
on public.lead_sessions for insert to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Lead sessions are editable by owner" on public.lead_sessions;
create policy "Lead sessions are editable by owner"
on public.lead_sessions for update to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Profiles are readable by owner" on public.profiles;
create policy "Profiles are readable by owner"
on public.profiles for select to authenticated
using (auth.uid() = id);

drop policy if exists "Profiles are editable by owner" on public.profiles;
create policy "Profiles are editable by owner"
on public.profiles for update to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Profiles can be inserted by owner" on public.profiles;
create policy "Profiles can be inserted by owner"
on public.profiles for insert to authenticated
with check (auth.uid() = id);

commit;
```

## Etap 1 - uproszczona baza Doorka

Ten SQL:
- zostawia prosty model: `profiles`, `contacts`, `clients`,
- usuwa nadmiarowe tabele robocze i stare moduły poza zakresem,
- na końcu usuwa wszystkie tabele z `public` poza `profiles`, `contacts`, `clients`,
- usuwa wszystkie dotychczasowe kontakty i klientów,
- zostawia tylko profil konta `kcprstlmch@gmail.com`,
- usuwa stare kolumny z `contacts` i `clients`,
- nie usuwa użytkowników z `auth.users`.

Przed uruchomieniem przeczytaj całość.

## Przywrócenie kontaktów do aktywnej listy

Ten SQL przywraca kontakty ukryte podczas testów, czyli czyści pola archiwum i przeniesienia do Moi Klienci.

```sql
update public.contacts
set
  archived_at = null,
  moved_to_client_at = null;
```

## Awaryjne przywrócenie kontaktów do mojego konta

Ten SQL przypisuje kontakty do konta `kcprstlmch@gmail.com`, odkrywa je i normalizuje stare statusy kontaktów.

```sql
update public.contacts
set
  agent_id = (
    select id
    from auth.users
    where email = 'kcprstlmch@gmail.com'
    limit 1
  ),
  archived_at = null,
  moved_to_client_at = null,
  status = case
    when status in ('signed_contract', 'lead', 'client') then 'scheduled_meeting'
    when status in ('contact', 'quick_contact', 'to_visit', 'to_call', 'visit_required') then 'contact'
    when status = 'lost' then 'not_interested'
    when status is null then 'scheduled_meeting'
    else status
  end
where exists (
  select 1
  from auth.users
  where email = 'kcprstlmch@gmail.com'
);
```

```sql
begin;

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  role text not null default 'agent',
  full_name text,
  phone text,
  avatar_path text
);

alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('agent', 'admin', 'moderator'));

alter table public.profiles enable row level security;

drop policy if exists "Profiles are readable by owner" on public.profiles;
create policy "Profiles are readable by owner"
on public.profiles
for select
to authenticated
using (auth.uid() = id);

drop policy if exists "Profiles are editable by owner" on public.profiles;
create policy "Profiles are editable by owner"
on public.profiles
for update
to authenticated
using (auth.uid() = id)
with check (auth.uid() = id);

drop policy if exists "Profiles can be inserted by owner" on public.profiles;
create policy "Profiles can be inserted by owner"
on public.profiles
for insert
to authenticated
with check (auth.uid() = id);

insert into public.profiles (id, email, role)
select id, email, 'admin'
from auth.users
where email = 'kcprstlmch@gmail.com'
on conflict (id) do update
set
  email = excluded.email,
  role = 'admin';

create table if not exists public.contacts (
  id uuid primary key default gen_random_uuid()
);

alter table public.contacts
  add column if not exists agent_id uuid references auth.users(id) on delete cascade,
  add column if not exists contact_name text,
  add column if not exists phone text,
  add column if not exists address text,
  add column if not exists status text,
  add column if not exists note text,
  add column if not exists contact_date date,
  add column if not exists contact_time time,
  add column if not exists meeting_time time,
  add column if not exists contact_quality text,
  add column if not exists contact_notification timestamptz,
  add column if not exists archived_at timestamptz,
  add column if not exists moved_to_client_at timestamptz;

do $do$
declare
  constraint_name text;
begin
  for constraint_name in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'public'
      and rel.relname = 'contacts'
      and con.contype = 'c'
      and pg_get_constraintdef(con.oid) ilike '%status%'
  loop
    execute format('alter table public.contacts drop constraint if exists %I', constraint_name);
  end loop;
end
$do$;

do $do$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'contacts' and column_name = 'user_id'
  ) then
    execute 'update public.contacts set agent_id = coalesce(agent_id, user_id)';
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'contacts' and column_name = 'first_name'
  ) then
    execute 'update public.contacts
      set contact_name = coalesce(
        nullif(contact_name, ''''),
        nullif(trim(concat_ws('' '', first_name, last_name)), '''')
      )';
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'contacts' and column_name = 'lead_day'
  ) then
    execute 'update public.contacts
      set contact_date = coalesce(contact_date, lead_day::date)
      where lead_day is not null';
  end if;

  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'contacts' and column_name = 'lead_time'
  ) then
    execute 'update public.contacts
      set contact_time = coalesce(contact_time, lead_time::time),
          meeting_time = coalesce(meeting_time, lead_time::time)
      where lead_time is not null';
  end if;

end
$do$;

update public.contacts
set status = case status
  when 'quick_contact' then 'contact'
  when 'to_visit' then 'contact'
  when 'to_call' then 'contact'
  when 'visit_required' then 'contact'
  when 'lead' then 'scheduled_meeting'
  when 'client' then 'scheduled_meeting'
  when 'lost' then 'not_interested'
  else status
end
where status in ('quick_contact', 'to_visit', 'to_call', 'visit_required', 'lead', 'client', 'lost');

update public.contacts
set
  status = 'scheduled_meeting',
  contact_date = current_date + ((floor(random() * 14)::int) + 1),
  contact_time = make_time((9 + floor(random() * 11)::int), (ARRAY[0, 15, 30, 45])[1 + floor(random() * 4)::int], 0),
  meeting_time = make_time((9 + floor(random() * 11)::int), (ARRAY[0, 15, 30, 45])[1 + floor(random() * 4)::int], 0),
  contact_quality = coalesce(contact_quality, (ARRAY['S', 'M', 'L', 'XL'])[1 + floor(random() * 4)::int])
where status = 'signed_contract';

alter table public.contacts
  drop constraint if exists contacts_status_check;

alter table public.contacts
  add constraint contacts_status_check
  check (status in (
    'scheduled_meeting',
    'meeting_active',
    'meeting_done',
    'signed_contract',
    'interested',
    'contact',
    'postponed',
    'not_interested',
    'no_contact'
  ));

drop policy if exists contacts_select_own on public.contacts;
drop policy if exists contacts_insert_own on public.contacts;
drop policy if exists contacts_update_own on public.contacts;
drop policy if exists contacts_delete_own on public.contacts;
drop table if exists public.activities cascade;

alter table public.contacts
  drop column if exists first_name,
  drop column if exists last_name,
  drop column if exists user_id,
  drop column if exists lead_day,
  drop column if exists lead_time,
  drop column if exists created_at,
  drop column if exists updated_at;

create index if not exists contacts_agent_id_idx on public.contacts(agent_id);
create index if not exists contacts_status_idx on public.contacts(status);
create index if not exists contacts_contact_notification_idx on public.contacts(contact_notification);

alter table public.contacts enable row level security;

drop policy if exists "Contacts are readable by owner" on public.contacts;
create policy "Contacts are readable by owner"
on public.contacts
for select
to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contacts are insertable by owner" on public.contacts;
create policy "Contacts are insertable by owner"
on public.contacts
for insert
to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Contacts are editable by owner" on public.contacts;
create policy "Contacts are editable by owner"
on public.contacts
for update
to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Contacts are deletable by owner" on public.contacts;
create policy "Contacts are deletable by owner"
on public.contacts
for delete
to authenticated
using (auth.uid() = agent_id);

create table if not exists public.clients (
  id uuid primary key default gen_random_uuid()
);

alter table public.clients
  add column if not exists agent_id uuid references auth.users(id) on delete cascade,
  add column if not exists source_contact_id uuid references public.contacts(id) on delete set null,
  add column if not exists client_name text,
  add column if not exists phone text,
  add column if not exists correspondence_address text,
  add column if not exists installation_address text,
  add column if not exists product_name text,
  add column if not exists contract_signed_at date,
  add column if not exists contract_number text,
  add column if not exists net_amount numeric(12,2),
  add column if not exists gross_amount numeric(12,2),
  add column if not exists commission_amount numeric(12,2),
  add column if not exists status text,
  add column if not exists execution_method text,
  add column if not exists payment_method text,
  add column if not exists document_1_name text,
  add column if not exists document_1_path text,
  add column if not exists document_2_name text,
  add column if not exists document_2_path text,
  add column if not exists last_activity_at timestamptz not null default now(),
  add column if not exists archived_at timestamptz;

alter table public.clients
  alter column status set default 'signed_contract';

do $do$
declare
  constraint_name text;
begin
  for constraint_name in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'public'
      and rel.relname = 'clients'
      and con.contype = 'c'
      and (
        pg_get_constraintdef(con.oid) ilike '%status%'
        or pg_get_constraintdef(con.oid) ilike '%execution_method%'
      )
  loop
    execute format('alter table public.clients drop constraint if exists %I', constraint_name);
  end loop;
end
$do$;

alter table public.clients
  drop constraint if exists clients_status_check;

alter table public.clients
  add constraint clients_status_check
  check (status in (
    'signed_contract',
    'financing_approved',
    'partial_payment_paid',
    'in_installation',
    'installed',
    'reported_to_grid_operator',
    'subsidy_reported',
    'lost'
  ));

alter table public.clients
  drop constraint if exists clients_execution_method_check;

alter table public.clients
  add constraint clients_execution_method_check
  check (execution_method in ('gotowka', 'finansowanie'));

alter table public.clients
  drop column if exists name,
  drop column if exists residential_address,
  drop column if exists installation_address_same_as_residential,
  drop column if exists email,
  drop column if exists installation_photo_names,
  drop column if exists credit_agreement_file_names,
  drop column if exists payment_method_old,
  drop column if exists vat_rate,
  drop column if exists markup,
  drop column if exists client_own_contribution,
  drop column if exists additional_costs,
  drop column if exists source,
  drop column if exists created_at,
  drop column if exists updated_at;

create index if not exists clients_agent_id_idx on public.clients(agent_id);
create index if not exists clients_status_idx on public.clients(status);
create index if not exists clients_last_activity_at_idx on public.clients(last_activity_at desc);

alter table public.clients enable row level security;

drop policy if exists "Clients are readable by owner" on public.clients;
create policy "Clients are readable by owner"
on public.clients
for select
to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Clients are insertable by owner" on public.clients;
create policy "Clients are insertable by owner"
on public.clients
for insert
to authenticated
with check (auth.uid() = agent_id);

drop policy if exists "Clients are editable by owner" on public.clients;
create policy "Clients are editable by owner"
on public.clients
for update
to authenticated
using (auth.uid() = agent_id)
with check (auth.uid() = agent_id);

drop policy if exists "Clients are deletable by owner" on public.clients;
create policy "Clients are deletable by owner"
on public.clients
for delete
to authenticated
using (auth.uid() = agent_id);

do $do$
declare
  table_name_to_drop text;
begin
  for table_name_to_drop in
    select tablename
    from pg_tables
    where schemaname = 'public'
      and tablename not in ('profiles', 'contacts', 'clients')
  loop
    execute format('drop table if exists public.%I cascade', table_name_to_drop);
  end loop;
end
$do$;

delete from public.clients;
delete from public.contacts;
delete from public.profiles
where email <> 'kcprstlmch@gmail.com';

commit;
```
