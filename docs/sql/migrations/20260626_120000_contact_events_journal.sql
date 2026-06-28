-- Doorka contact events journal.
-- Safe migration: keeps all contacts and adds durable contact history support.
-- Run manually in Supabase SQL Editor.

begin;

create extension if not exists pgcrypto;

alter table public.contacts
  add column if not exists archived_at timestamptz;

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

create index if not exists contacts_archived_at_idx
on public.contacts(archived_at);

create index if not exists contact_events_agent_created_at_idx
on public.contact_events(agent_id, created_at desc);

create index if not exists contact_events_contact_created_at_idx
on public.contact_events(contact_id, created_at desc);

create index if not exists contact_events_type_created_at_idx
on public.contact_events(event_type, created_at desc);

alter table public.contact_events enable row level security;

drop policy if exists "Contact events are readable by owner" on public.contact_events;
create policy "Contact events are readable by owner"
on public.contact_events for select to authenticated
using (auth.uid() = agent_id);

drop policy if exists "Contact events are insertable by owner" on public.contact_events;
create policy "Contact events are insertable by owner"
on public.contact_events for insert to authenticated
with check (auth.uid() = agent_id);

commit;
