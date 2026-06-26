-- Doorka Supabase baseline.
-- Safe migration: updates schema, indexes and RLS without deleting app data.
-- Run manually in Supabase SQL Editor.

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

alter table public.contacts
  drop constraint if exists contacts_meeting_result_check;

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
  add column if not exists client_process_note text,
  add column if not exists status text not null default 'signed_contract',
  add column if not exists execution_method text,
  add column if not exists payment_method text,
  add column if not exists document_1_name text,
  add column if not exists document_1_path text,
  add column if not exists document_2_name text,
  add column if not exists document_2_path text,
  add column if not exists last_activity_at timestamptz not null default now(),
  add column if not exists archived_at timestamptz;

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
  check (execution_method is null or execution_method in ('gotowka', 'finansowanie'));

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

alter table public.work_cycles
  drop constraint if exists work_cycles_status_check;

alter table public.work_cycles
  add constraint work_cycles_status_check
  check (status in ('open', 'closed'));

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

create index if not exists contacts_agent_id_idx on public.contacts(agent_id);
create index if not exists contacts_status_idx on public.contacts(status);
create index if not exists contacts_contact_date_idx on public.contacts(contact_date);
create index if not exists contacts_contact_notification_idx on public.contacts(contact_notification);
create index if not exists clients_agent_id_idx on public.clients(agent_id);
create index if not exists clients_status_idx on public.clients(status);
create index if not exists clients_last_activity_at_idx on public.clients(last_activity_at desc);
create index if not exists lead_sessions_agent_id_idx on public.lead_sessions(agent_id);
create index if not exists work_cycles_agent_id_idx on public.work_cycles(agent_id);
create index if not exists contact_events_contact_id_idx on public.contact_events(contact_id);

alter table public.profiles enable row level security;
alter table public.contacts enable row level security;
alter table public.clients enable row level security;
alter table public.lead_sessions enable row level security;
alter table public.work_cycles enable row level security;
alter table public.contact_events enable row level security;

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
