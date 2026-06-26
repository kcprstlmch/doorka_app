-- Doorka destructive maintenance script.
-- Purpose: remove current contact work statuses and make "no status" explicit as NULL.
-- Run manually in Supabase SQL Editor only after confirming this is intended.

begin;

-- Clear assigned work statuses from existing contacts.
-- This does not change the technical lifecycle/status in `contacts.status`.
update public.contacts
set contact_status = null
where contact_status is not null;

-- Remove custom contact status definitions.
-- Contact types are preserved because they use kind = 'type'.
delete from public.contact_status_options
where kind = 'status';

commit;
