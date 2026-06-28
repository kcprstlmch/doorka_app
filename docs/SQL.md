# SQL

Ten plik opisuje aktualny model danych i historyczne notatki SQL.
Nowe zmiany Supabase dopisuj jako osobne, małe migracje w `docs/sql/migrations/`.

Zasada pracy od 2026-06-19: przy zwykłych zmianach nie kasujemy kontaktów, klientów, profili ani innych danych użytkowników.
Migracje mają dotyczyć tylko zakresu wskazanego przez użytkownika i powinny używać bezpiecznych operacji typu `create table if not exists`, `alter table ... add column if not exists`, `create index if not exists` oraz aktualizacji RLS.

Skrypty czyszczące lub resetujące dane trzymamy wyłącznie w `docs/sql/destructive/` i uruchamiamy tylko po osobnej, wyraźnej zgodzie.
Aktualna bezpieczna migracja bazowa znajduje się w `docs/sql/migrations/20260619_120000_baseline_non_destructive.sql`.
Aktualna bezpieczna migracja modelu Kontakt -> Umówione spotkanie -> Do realizacji znajduje się w `docs/sql/migrations/20260622_230000_contact_lifecycle_non_destructive.sql`.
Aktualna bezpieczna migracja dziennika zdarzeń kontaktu znajduje się w `docs/sql/migrations/20260626_120000_contact_events_journal.sql`.
Nic z tego pliku nie wykonuje się automatycznie.

## Aktualna mapa bazy danych

Ta sekcja jest szybkim podglądem tego, jakie tabele i kolumny składają się na aktualny model danych aplikacji.
Wiersz oznacza jeden rekord w danej tabeli, np. jeden agent, jeden kontakt albo jeden klient.

### `auth.users`

Tabela Supabase Auth zarządzana przez Supabase.
Aplikacja nie zapisuje tutaj ręcznie danych poza standardową rejestracją i logowaniem.

Jeden wiersz = jedno konto użytkownika.

| Kolumna | Znaczenie |
| --- | --- |
| `id` | Główne ID użytkownika. To ID jest używane jako właściciel danych w aplikacji. |
| `email` | E-mail logowania użytkownika. |
| `raw_user_meta_data` | Techniczne metadane użytkownika, np. tymczasowe `full_name` tworzone z e-maila. |

### `public.profiles`

Profil aplikacyjny użytkownika.
Tabela jest połączona z `auth.users`.

Jeden wiersz = jeden profil użytkownika aplikacji.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID profilu. Jest takie samo jak `auth.users.id`. |
| `email` | `text` | E-mail użytkownika. |
| `role` | `text` | Rola użytkownika, np. `agent`, `admin`, `moderator`. |
| `full_name` | `text` | Nazwa profilu. Na teraz może być technicznie uzupełniona początkiem e-maila. |
| `phone` | `text` | Telefon użytkownika, opcjonalny. |
| `avatar_path` | `text` | Ścieżka albo adres avatara. |
| `auto_record_meetings` | `boolean` | Czy spotkania mają się automatycznie nagrywać. |
| `default_daily_goal` | `int` | Domyślny cel umawiania spotkań. |

### `public.contacts`

Lista zebranych leadów/kontaktów agenta.
Każdy rekord musi być przypisany do konkretnego agenta przez `agent_id`.

Jeden wiersz = jeden kontakt w pierwszym etapie życia leada.
Umówione spotkania powinny docelowo trafiać do `public.meetings`, a realizacje do `public.clients`.
Kolumny spotkaniowe w `contacts` zostają tylko dla kompatybilności ze starszą wersją aplikacji i migracji danych.

Decyzja architektoniczna:
kontakt jest bazowym obiektem procesu.
Umówione spotkanie to kontakt na etapie/systemowym statusie `scheduled_meeting`.
Spisana umowa przenosi dane do `clients`.
Zamknięte spotkania z powodami i wnioskami powinny trafiać do osobnej sekcji `Zapamiętane spotkania`, żeby aktywne ekrany nie były zaśmiecone historią.

Docelowy widok kontaktu w aplikacji:

| Pole w aplikacji | Gdzie jest w SQL | Znaczenie |
| --- | --- | --- |
| Dane kontaktu | `contacts.contact_name` | Imię, nazwa albo dane osoby. |
| Adres | `contacts.address` | Adres kontaktu. |
| Nr telefonu | `contacts.phone` | Numer telefonu kontaktu. |
| Typ kontaktu | `contact_type_assignments` + `contact_status_options(kind = 'type')` | Maksymalnie 3 aktywne typy kontaktu. |
| Status kontaktu | `contacts.contact_status` | Roboczy status ustawiany przez agenta. Brak statusu = `NULL`. |
| Uwagi / notatki | `contacts.note` | Ręczna notatka agenta. |

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID kontaktu. |
| `agent_id` | `uuid` | Właściciel kontaktu. Wskazuje na `auth.users.id`. |
| `contact_name` | `text` | Dane kontaktu, np. imię/nazwa klienta. |
| `phone` | `text` | Telefon kontaktu. |
| `address` | `text` | Adres kontaktu lub spotkania. |
| `status` | `text` | Techniczny etap rekordu. Dla zwykłego kontaktu powinien mieć wartość `contact`. |
| `contact_type` | `text` | Historyczny pojedynczy typ kontaktu. Nowa mechanika wielu typów używa `contact_type_assignments`. |
| `contact_status` | `text` | Elastyczny status kontaktu ustawiany przez agenta. Brak ustawionego statusu to `NULL`. |
| `lifecycle_stage` | `text` | Etap życia rekordu: `contact`, `meeting`, `in_progress`. |
| `note` | `text` | Notatka wpisana przez agenta. |
| `contact_date` | `date` | Data kontaktu albo data umówionego spotkania. |
| `contact_time` | `time` | Czas kontaktu, jeśli jest używany. |
| `meeting_time` | `time` | Godzina umówionego spotkania. |
| `contact_quality` | `text` | Znaczniki jakości kontaktu, np. `favorite,top`. `favorite` oznacza gwiazdkę, a jakość/potencjał może mieć wartości `top`, `strong`, `relation`, `weak`. |
| `contact_notification` | `timestamptz` | Termin przypomnienia dla kontaktu. |
| `meeting_started_at` | `timestamptz` | Czas rozpoczęcia spotkania. |
| `meeting_finished_at` | `timestamptz` | Czas zakończenia spotkania. |
| `meeting_result` | `text` | Wynik spotkania, np. `signed_contract`, `interested`, `not_interested`, `missed`, `postponed`. |
| `not_interested_reason` | `text` | Powód braku zainteresowania. |
| `local_recording_path` | `text` | Lokalna ścieżka do nagrania spotkania. |
| `ai_summary` | `text` | Krótka konkluzja AI ze spotkania. |
| `ai_analysis` | `text` | Pełniejsza analiza AI ze spotkania. |
| `archived_at` | `timestamptz` | Data przeniesienia do archiwum. `NULL` oznacza aktywny rekord. |
| `moved_to_client_at` | `timestamptz` | Data przeniesienia kontaktu do klientów. |
| `created_at` | `timestamptz` | Data utworzenia rekordu. |
| `updated_at` | `timestamptz` | Data ostatniej aktualizacji rekordu. |

Dozwolone wartości technicznego pola `contacts.status`:

`contacts.status` nie jest roboczym statusem kontaktu wybieranym przez agenta.
Roboczy status kontaktu jest w `contacts.contact_status` i może być `NULL`.

| Status | Znaczenie |
| --- | --- |
| `scheduled_meeting` | Umówione spotkanie. |
| `meeting_active` | Spotkanie w trakcie. |
| `meeting_done` | Spotkanie odbyte. |
| `signed_contract` | Spotkanie zakończone spisaną umową. |
| `interested` | Klient zainteresowany, ale bez umowy. |
| `contact` | Zwykły kontakt. |
| `postponed` | Spotkanie przełożone. |
| `not_interested` | Klient niezainteresowany. |
| `no_contact` | Brak kontaktu. |

`to_call` i `to_visit` są starymi wartościami historycznymi.
Nie powinny być już tworzone jako techniczny `contacts.status`.
Jeśli agent chce taki status roboczy, powinien dodać go w Ustawieniach jako własny status, a kontakt zapisze go w `contacts.contact_status`.

Dozwolone wartości `contacts.lifecycle_stage`:

| Etap | Znaczenie |
| --- | --- |
| `contact` | Kontakt / zebrany lead. |
| `meeting` | Rekord został albo zostanie przeniesiony do umówionego spotkania. |
| `in_progress` | Rekord został albo zostanie przeniesiony do realizacji. |

### `public.meetings`

Lista umówionych spotkań agenta.
Każde spotkanie musi być przypisane do konkretnego agenta przez `agent_id`.

Jeden wiersz = jedno umówione spotkanie w drugim etapie życia leada.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID spotkania. |
| `agent_id` | `uuid` | Właściciel spotkania. Wskazuje na `auth.users.id`. |
| `source_contact_id` | `uuid` | Kontakt źródłowy, z którego powstało spotkanie. |
| `contact_name` | `text` | Dane kontaktu/klienta. |
| `phone` | `text` | Telefon klienta. |
| `address` | `text` | Adres spotkania. |
| `meeting_date` | `date` | Data umówionego spotkania. |
| `meeting_time` | `time` | Godzina umówionego spotkania. |
| `quality` | `text` | Pole historyczne. Skala jakości spotkania nie jest aktualnie używana w UX. |
| `note` | `text` | Uwagi/notatki do spotkania. |
| `result` | `text` | Wynik spotkania po rozliczeniu. |
| `result_reason` | `text` | Powód wyniku, jeśli jest potrzebny. |
| `archived_at` | `timestamptz` | Data przeniesienia do archiwum. `NULL` oznacza aktywny rekord. |
| `created_at` | `timestamptz` | Data utworzenia rekordu. |
| `updated_at` | `timestamptz` | Data ostatniej aktualizacji rekordu. |

Dozwolone wartości `meetings.result`:

| Wynik | Znaczenie |
| --- | --- |
| `sold` | Sprzedane / przechodzi do realizacji. |
| `not_sold` | Spotkanie odbyte, ale bez sprzedaży. |
| `postponed` | Spotkanie przełożone. |
| `not_interested` | Klient niezainteresowany. |

### `public.contact_status_options`

Lista typów i statusów kontaktu tworzonych przez agenta w ustawieniach.
Każdy agent widzi tylko swoje opcje.

Jeden wiersz = jedna opcja typu albo statusu kontaktu.
Typy kontaktów działają jak tagi/karteczki, np. `VOTUM`, `świadczenia zdrowotne`, `karteczki`.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID opcji. |
| `agent_id` | `uuid` | Właściciel opcji. Wskazuje na `auth.users.id`. |
| `kind` | `text` | Rodzaj opcji: `type` albo `status`. |
| `label` | `text` | Nazwa widoczna w aplikacji. |
| `color` | `text` | Kolor opcji, np. `#8A8F98`. |
| `sort_order` | `int` | Kolejność wyświetlania. |
| `is_active` | `boolean` | Czy opcja jest aktywna. |
| `created_at` | `timestamptz` | Data utworzenia opcji. |
| `updated_at` | `timestamptz` | Data ostatniej aktualizacji opcji. |

Limit: maksymalnie 10 aktywnych typów i maksymalnie 10 aktywnych statusów na jednego agenta.

### `public.contact_type_assignments`

Tabela łącząca kontakty z wieloma typami.
Dzięki temu jeden kontakt może mieć kilka typów jednocześnie, np. `VOTUM` + `świadczenia zdrowotne`.

Jeden wiersz = jedno przypisanie jednego typu do jednego kontaktu.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `contact_id` | `uuid` | Kontakt, do którego przypisano typ. |
| `type_id` | `uuid` | Typ kontaktu z `contact_status_options`, gdzie `kind = 'type'`. |
| `agent_id` | `uuid` | Właściciel przypisania. Wskazuje na `auth.users.id`. |
| `created_at` | `timestamptz` | Data przypisania typu do kontaktu. |

Zasada UI:

| Miejsce | Zachowanie |
| --- | --- |
| Kafelek kontaktu / lista | Obok nazwy kontaktu pokazujemy tylko kolorowe kropki typów, bez nazw. |
| Szczegóły kontaktu | Pokazujemy pełne nazwy typów wraz z kolorami. |
| Edycja kontaktu | Agent może zaznaczyć wiele typów kontaktu. |

### `public.contact_events`

Dziennik zdarzeń kontaktu.
To ta tabela jest docelową prawdą historyczną dla statystyk.

Jeden wiersz = jedno zdarzenie w życiu kontaktu.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID zdarzenia. |
| `agent_id` | `uuid` | Właściciel zdarzenia. Wskazuje na `auth.users.id`. |
| `contact_id` | `uuid` | Kontakt, którego dotyczy zdarzenie. |
| `work_cycle_id` | `uuid` | Cykl pracy, jeśli zdarzenie było przypisane do cyklu. |
| `event_type` | `text` | Techniczny typ zdarzenia, np. `contact_created`, `meeting_scheduled`, `contract_signed`. |
| `event_note` | `text` | Krótki opis zdarzenia widoczny dla agenta. |
| `metadata` | `jsonb` | Dodatkowe dane zdarzenia, np. poprzedni status, nowy status, data spotkania. |
| `created_at` | `timestamptz` | Data zapisania zdarzenia. |

Przykładowe typy zdarzeń:

| `event_type` | Znaczenie |
| --- | --- |
| `contact_created` | Utworzono kontakt. |
| `contact_updated` | Zmieniono dane kontaktu. |
| `contact_type_changed` | Zmieniono typ kontaktu. |
| `contact_status_changed` | Zmieniono status kontaktu. |
| `meeting_scheduled` | Umówiono spotkanie. |
| `meeting_rescheduled` | Przełożono spotkanie. |
| `meeting_not_sold` | Spotkanie niesprzedane. |
| `meeting_missed` | Spotkanie nieodbyte. |
| `contract_signed` | Spisano umowę. |
| `contact_hidden` | Kontakt usunięto z aktywnego widoku, ale nie skasowano z bazy. |

### `public.clients`

Lista klientów w realizacji, czyli trzeci etap życia leada.
Klient może powstać ze spotkania albo zostać dodany ręcznie.
Każdy klient musi być przypisany do konkretnego agenta przez `agent_id`.

Jeden wiersz = jeden klient w sekcji klientów.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID klienta. |
| `agent_id` | `uuid` | Właściciel klienta. Wskazuje na `auth.users.id`. |
| `source_contact_id` | `uuid` | Kontakt źródłowy, z którego powstał klient. |
| `source_meeting_id` | `uuid` | Spotkanie źródłowe, z którego powstała realizacja. |
| `client_name` | `text` | Dane klienta. |
| `phone` | `text` | Telefon klienta. |
| `correspondence_address` | `text` | Adres korespondencyjny. |
| `installation_address` | `text` | Adres instalacji. |
| `product_name` | `text` | Produkt albo usługa klienta. |
| `contract_signed_at` | `date` | Data podpisania umowy. |
| `contract_number` | `text` | Numer umowy, jeśli jest używany. |
| `net_amount` | `numeric(12,2)` | Kwota netto, jeśli jest używana. |
| `gross_amount` | `numeric(12,2)` | Kwota brutto. |
| `commission_amount` | `numeric(12,2)` | Prowizja, jeśli jest używana. |
| `client_process_note` | `text` | Opis klienta i procesu. |
| `status` | `text` | Status klienta, domyślnie `signed_contract`. |
| `execution_method` | `text` | Sposób realizacji. |
| `payment_method` | `text` | Sposób płatności, jeśli jest używany. |
| `document_1_name` | `text` | Nazwa pierwszego dokumentu. |
| `document_1_path` | `text` | Ścieżka pierwszego dokumentu. |
| `document_2_name` | `text` | Nazwa drugiego dokumentu. |
| `document_2_path` | `text` | Ścieżka drugiego dokumentu. |
| `last_activity_at` | `timestamptz` | Data ostatniej aktywności przy kliencie. |
| `archived_at` | `timestamptz` | Data przeniesienia klienta do archiwum. `NULL` oznacza aktywny rekord. |

### `public.lead_sessions`

Historyczna/robocza tabela sesji umawiania spotkań.
Na obecnym etapie część liczenia może być wykonywana z kontaktów przypisanych do daty, ale tabela zostaje opisana, bo występuje w SQL.

Jeden wiersz = jedna sesja pracy agenta danego dnia.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID sesji. |
| `agent_id` | `uuid` | Właściciel sesji. Wskazuje na `auth.users.id`. |
| `session_date` | `date` | Data sesji. |
| `scheduled_meetings_count` | `int` | Liczba umówionych spotkań zapisana w sesji. |
| `collected_contacts_count` | `int` | Liczba zebranych kontaktów zapisana w sesji. |
| `work_seconds` | `int` | Czas pracy w sekundach. |
| `break_seconds` | `int` | Czas przerwy w sekundach. |
| `created_at` | `timestamptz` | Data utworzenia sesji. |

### `public.work_cycles`

Historyczna/robocza tabela cykli pracy.
Opisuje cykl leadowania i sprzedaży, jeśli ten mechanizm wróci do użycia.

Jeden wiersz = jeden cykl pracy agenta.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID cyklu. |
| `agent_id` | `uuid` | Właściciel cyklu. Wskazuje na `auth.users.id`. |
| `lead_date` | `date` | Data dnia umawiania spotkań. |
| `sales_date` | `date` | Data dnia sprzedażowego. |
| `status` | `text` | Status cyklu, np. `open` albo `closed`. |
| `scheduled_count` | `int` | Liczba umówionych spotkań w cyklu. |
| `leads_count` | `int` | Liczba leadów w cyklu. |
| `completed_meetings_count` | `int` | Liczba odbytych spotkań. |
| `postponed_count` | `int` | Liczba przełożonych spotkań. |
| `missed_count` | `int` | Liczba spotkań, które się nie odbyły. |
| `signed_contracts_count` | `int` | Liczba spisanych umów. |
| `closed_at` | `timestamptz` | Data zamknięcia cyklu. |
| `created_at` | `timestamptz` | Data utworzenia cyklu. |

### `public.contact_events`

Historyczna/robocza tabela zdarzeń na kontakcie.
Może służyć jako dziennik zmian, jeśli wrócimy do pełniejszej historii kontaktów.

Jeden wiersz = jedno zdarzenie wykonane na kontakcie.

| Kolumna | Typ | Znaczenie |
| --- | --- | --- |
| `id` | `uuid` | ID zdarzenia. |
| `agent_id` | `uuid` | Właściciel zdarzenia. Wskazuje na `auth.users.id`. |
| `contact_id` | `uuid` | Kontakt, którego dotyczy zdarzenie. |
| `work_cycle_id` | `uuid` | Cykl pracy powiązany ze zdarzeniem. |
| `event_type` | `text` | Typ zdarzenia. |
| `event_note` | `text` | Notatka do zdarzenia. |
| `metadata` | `jsonb` | Dodatkowe dane zdarzenia. |
| `created_at` | `timestamptz` | Data utworzenia zdarzenia. |

## Naprawa rejestracji użytkownika

Jeżeli przy zakładaniu konta pojawia się błąd Supabase Auth typu `Database error saving new user` albo `error adding new user`, należy ręcznie uruchomić w Supabase SQL Editor migrację:

`docs/sql/migrations/20260619_121000_auth_profile_trigger.sql`

Nie uruchamiaj skryptów z `docs/sql/destructive/`, jeśli chcesz tylko naprawić rejestrację.

Ten SQL tworzy albo naprawia trigger `on_auth_user_created`, który po utworzeniu użytkownika w `auth.users` zakłada odpowiadający mu wpis w `public.profiles`.
Przed utworzeniem poprawnego triggera usuwa stare niestandardowe triggery z `auth.users`, bo stary trigger pod inną nazwą również może powodować błąd rejestracji.
Rejestracja w aplikacji pozostaje minimalna: wymagane są tylko e-mail i hasło.

## Etap 1.2 - Contact Mechanics

Ten historyczny blok przygotowywał bazę pod mechanikę kontaktów 1.2.
Reset danych został usunięty z normalnego procesu pracy.
Aktualną bezpieczną wersją bazową jest migracja `docs/sql/migrations/20260619_120000_baseline_non_destructive.sql`.

Przed uruchomieniem nowych zmian:
- dodaj osobną migrację w `docs/sql/migrations/`,
- upewnij się, że migracja nie kasuje istniejących kontaktów ani klientów,
- uruchamiaj ręcznie w Supabase SQL Editor tylko zakres danej migracji.

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

-- Nie usuwamy kolumn przy zwyklych zmianach.
-- Jesli `contact_product` ma zostac usuniete, przygotuj osobny skrypt w `docs/sql/destructive/`.

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
    'to_call',
    'to_visit',
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

-- Reset danych zostal usuniety z normalnego procesu migracji.
-- Jesli potrzebny jest swiadomy reset, przygotuj osobny skrypt w `docs/sql/destructive/`.

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
- był historycznym blokiem porządkującym model `profiles`, `contacts`, `clients`,
- nie jest już standardowym sposobem pracy z Supabase,
- nie powinien być kopiowany jako kolejna migracja,
- został zastąpiony zasadą małych, osobnych migracji w `docs/sql/migrations/`,
- działania usuwające dane albo kolumny wymagają osobnego skryptu w `docs/sql/destructive/` i wyraźnej zgody.

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
    'to_call',
    'to_visit',
    'postponed',
    'not_interested',
    'no_contact'
  ));

drop policy if exists contacts_select_own on public.contacts;
drop policy if exists contacts_insert_own on public.contacts;
drop policy if exists contacts_update_own on public.contacts;
drop policy if exists contacts_delete_own on public.contacts;
-- Nie usuwamy tabel przy zwyklych zmianach.
-- Jesli `activities` ma zostac usuniete, przygotuj osobny skrypt w `docs/sql/destructive/`.

-- Nie usuwamy starych kolumn kontaktow przy zwyklych zmianach.
-- Jesli kolumny maja zostac usuniete, przygotuj osobny skrypt w `docs/sql/destructive/`.

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

-- Nie usuwamy starych kolumn klientow przy zwyklych zmianach.
-- Jesli kolumny maja zostac usuniete, przygotuj osobny skrypt w `docs/sql/destructive/`.

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

-- Masowe usuwanie tabel, klientow, kontaktow i profili zostalo usuniete z normalnego procesu SQL.
-- Jesli potrzebny jest taki reset, przygotuj osobny skrypt w `docs/sql/destructive/`
-- i uruchom go dopiero po osobnej zgodzie.

commit;
```
