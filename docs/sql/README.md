# SQL i Supabase

To jest glowne miejsce dla plikow SQL w projekcie.

## Struktura

- `migrations/` - zwykle, bezpieczne zmiany Supabase do recznego uruchomienia.
- `destructive/` - skrypty awaryjne, ktore moga usuwac albo nadpisywac dane.
- `../SQL.md` - mapa bazy danych i historyczny kontekst.

## Zasada nadrzedna

Przy zwyklych zmianach Supabase nie kasujemy kontaktow, klientow, profili ani innych danych uzytkownikow.

Kazda kolejna zmiana powinna byc osobnym plikiem w `docs/sql/migrations/` i dotyczyc tylko tego, o co poprosil uzytkownik.

Bezpieczne operacje:

- `create table if not exists`
- `alter table ... add column if not exists`
- `create index if not exists`
- `drop policy if exists` + `create policy`, gdy poprawiamy RLS

Aktualny dziennik zdarzen kontaktu jest w migracji:

- `migrations/20260626_120000_contact_events_journal.sql`

Ta migracja nie kasuje danych. Dodaje trwala historie kontaktow i wspiera zasade, ze przycisk `Usun` w aplikacji ukrywa kontakt z aktywnej pracy, ale nie usuwa go permanentnie z bazy.

Operacje wymagajace osobnej zgody:

- `delete from`
- `truncate`
- `drop table`
- `drop column`
- masowe przepisywanie wlascicieli danych
- reset kontaktow, klientow, profili albo statystyk

Takie skrypty trzymaj tylko w `docs/sql/destructive/`.
