# Model danych

Ten plik jest głównym źródłem prawdy dla aktualnego, uproszczonego modelu Supabase na etap 1.
Model ma być prosty, skuteczny i zgodny z tym, co aplikacja realnie pokazuje użytkownikowi.

## Zasady główne
Supabase jest głównym źródłem danych.
Każdy agent widzi tylko swoje dane dzięki RLS.
W tabelach zostają tylko dane potrzebne aplikacji na obecnym etapie.
Stare tabele z webowego CRM, takie jak `crm_leads`, `crm_recordings`, `crm_manager_agents`, `crm_recruitment_stats`, `calculator_states` i podobne, nie są częścią aktualnego modelu.

Na tym etapie zostają główne tabele:
- `profiles`
- `contacts`
- `clients`
- `lead_sessions`
- `work_cycles`
- `contact_events`

## `profiles`
Tabela profilu użytkownika połączona z Supabase Auth.

Ogólnie:
- przechowuje podstawowe dane konta,
- konto `kcprstlmch@gmail.com` jest kontem admina,
- hasło jest obsługiwane przez Supabase Auth, nie przez tabelę `profiles`.

## `contacts`
Tabela wszystkich kontaktów wszystkich agentów.
Każdy kontakt ma przypisanie do agenta, więc agent widzi tylko swoje kontakty.

Pola widoczne dla użytkownika:
- `contact_name`
- `phone`
- `address`
- `status`
- `note`

Pozostałe pola są techniczne i służą aplikacji, filtrom, powiadomieniom, archiwizacji oraz RLS.

Statusy kontaktów:
- Umówione spotkanie
- Spotkanie trwa
- Spotkanie odbyte
- Spisana umowa
- Zainteresowany
- Kontakt roboczy
- Do podjechania
- Do przedzwonienia
- Przełożone
- Niezainteresowany
- Brak kontaktu

Mechanika statusów i przepływów kontaktów jest opisana w `docs/mechanics/CONTACT_MECHANICS.md`.
Ten plik jest źródłem prawdy dla zachowania kontaktu, spotkania i cyklu pracy.

## `clients`
Tabela sekcji W realizacji.
Na tym etapie jeden wpis w `clients` oznacza jedną sprawę realizacyjną klienta z jednym produktem / umową.
Jeśli ta sama osoba kupuje kolejny produkt, na razie dodajemy ją jako kolejny wpis w `clients`.

W tej tabeli trzymamy też podstawowe informacje o produkcie, umowie, typie klienta/formie płatności (`execution_method`: gotówkowy albo na raty), statusie realizacji oraz maksymalnie dwóch plikach klienta.
Nie tworzymy na tym etapie osobnych tabel na produkty, statusy ani dokumenty.

## RLS
RLS ma pilnować, żeby agent widział tylko swoje rekordy w:
- `contacts`
- `clients`

Profil użytkownika jest widoczny tylko dla właściciela profilu.

## Statystyki
Statystyki mają być wyliczane z danych w `contacts` i `clients`.
Statystyki czasu leadowania i podsumowań sesji mają być wyliczane z `lead_sessions`.
Nie utrzymujemy osobnych ręcznie wpisywanych tabel statystyk na obecnym etapie.

## `lead_sessions`
Tabela sesji leadowania.
Zapisuje podsumowanie po kliknięciu "Koniec" w aktywnym kafelku Dashboardu.

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
Cykl łączy dzień leadowania i dzień sprzedażowy.
Służy do podsumowania cyklu oraz porównywania cyklu do poprzedniego cyklu.

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
Tabela historii działań kontaktu.
Zapisuje najważniejsze zdarzenia operacyjne i statystyczne.

Przykłady zdarzeń:
- dodanie kontaktu
- zmiana statusu
- start spotkania
- zakończenie spotkania
- przełożenie
- archiwizacja
- przeniesienie do W realizacji
- zapis konkluzji AI

Podstawowe pola:
- `agent_id`
- `contact_id`
- `work_cycle_id`
- `event_type`
- `event_note`
- `metadata`
- `created_at`

## Czyszczenie bazy
Docelowo w schemacie `public` zostawiamy tylko:
- `profiles`
- `contacts`
- `clients`
- `lead_sessions`
- `work_cycles`
- `contact_events`

Dotychczasowe kontakty i klienci mogą zostać wyczyszczeni.
W `profiles` zostaje konto `kcprstlmch@gmail.com`.
