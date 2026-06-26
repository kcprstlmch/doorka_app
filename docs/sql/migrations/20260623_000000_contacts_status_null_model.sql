-- Doorka contacts status model.
-- Safe migration: keeps contacts, makes work status nullable, and keeps
-- technical lifecycle status separate from agent work status.
-- Run manually in Supabase SQL Editor.

begin;

alter table public.contacts
  add column if not exists contact_status text;

-- A regular contact should stay in the technical `contact` lifecycle status.
alter table public.contacts
  alter column status set default 'contact';

-- Old helper statuses are no longer technical statuses.
-- Missing work status is represented as NULL.
update public.contacts
set
  status = 'contact',
  contact_status = null
where status in ('to_call', 'to_visit', 'quick_contact', 'visit_required');

-- Preserve the lifecycle distinction without forcing a work status.
update public.contacts
set lifecycle_stage = 'contact'
where lifecycle_stage is null
  and status = 'contact';

create index if not exists contacts_contact_status_idx
on public.contacts(contact_status);

commit;
