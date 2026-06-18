# Model danych

Ten plik jest glownym zrodlem prawdy dla aktualnego, uproszczonego modelu Supabase.
Model ma wspierac mechanike 1.2: umow spotkanie, dodaj kontakt, usun kontakt.

## Zasady glowne
Supabase jest glownym zrodlem danych.
Kazdy agent widzi tylko swoje dane dzieki RLS.
Stare tabele z webowego CRM nie sa czescia aktualnego modelu aplikacji.

Glowne tabele:
- `profiles`
- `contacts`
- `clients`
- `lead_sessions`
- `work_cycles`
- `contact_events`

## `profiles`
Tabela profilu uzytkownika polaczona z Supabase Auth.
Haslo jest obslugiwane przez Supabase Auth, nie przez `profiles`.

## `contacts`
Tabela wszystkich kontaktow i spotkan agentow.
Kazdy rekord ma przypisanie do agenta, wiec agent widzi tylko swoje dane.

Pola widoczne dla uzytkownika:
- `contact_name`
- `phone`
- `address`
- `status`
- `note`
- `contact_date`
- `contact_time`
- `meeting_time`

Statusy:
- `contact`
- `scheduled_meeting`
- `meeting_active`
- `meeting_done`
- `signed_contract`
- `interested`
- `not_interested`
- `no_contact`
- `postponed`

Stare statusy:
- `quick_contact`
- `to_visit`
- `to_call`
- `visit_required`

powinny byc mapowane do `contact`.

## `clients`
Tabela sekcji W realizacji.
Na tym etapie jeden wpis w `clients` oznacza jedna sprawe realizacyjna klienta.
Spisana umowa moze zostac przeniesiona z kontaktu do `clients`.

## `lead_sessions`
Tabela sesji dnia umawiania spotkan.
Zapisuje podsumowanie pracy po zakonczeniu sesji.

Podstawowe pola:
- `agent_id`
- `session_date`
- `scheduled_meetings_count`
- `collected_contacts_count`
- `work_seconds`
- `break_seconds`
- `created_at`

## `work_cycles`
Tabela cykli pracy agenta.
Cykl laczy dzien umawiania spotkan i dzien sprzedazowy.

Podstawowe pola:
- `agent_id`
- `lead_date`
- `sales_date`
- `status`
- `scheduled_count`
- `leads_count`
- `completed_meetings_count`
- `postponed_count`
- `missed_count`
- `signed_contracts_count`
- `closed_at`
- `created_at`

## `contact_events`
Tabela historii dzialan kontaktu.
Moze zapisywac:
- dodanie kontaktu,
- zmiane statusu,
- start spotkania,
- zakonczenie spotkania,
- przelozenie,
- archiwizacje,
- przeniesienie do W realizacji.

## RLS
RLS ma pilnowac, zeby agent widzial tylko swoje rekordy w:
- `contacts`
- `clients`
- `lead_sessions`
- `work_cycles`
- `contact_events`

Profil uzytkownika jest widoczny tylko dla wlasciciela profilu.

## Statystyki
Statystyki powinny byc wyliczane z danych w `contacts`, `clients` i `lead_sessions`.
Umowione spotkania sa liczone po rekordach spotkan z konkretna data, a nie po samym kliknieciu Start.
