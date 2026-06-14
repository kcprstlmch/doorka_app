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
- Zainteresowany
- Szybki kontakt
- Do podjechania
- Do przedzwonienia
- Niezainteresowany
- Brak kontaktu

## `clients`
Tabela sekcji Moi Klienci.
Na tym etapie jeden wpis w `clients` oznacza jedną sprawę klienta z jednym produktem / umową.
Jeśli ta sama osoba kupuje kolejny produkt, na razie dodajemy ją jako kolejny wpis w `clients`.

W tej tabeli trzymamy też podstawowe informacje o produkcie, umowie, płatności, statusie realizacji oraz maksymalnie dwóch plikach klienta.
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

## Czyszczenie bazy
Docelowo w schemacie `public` zostawiamy tylko:
- `profiles`
- `contacts`
- `clients`
- `lead_sessions`

Dotychczasowe kontakty i klienci mogą zostać wyczyszczeni.
W `profiles` zostaje konto `kcprstlmch@gmail.com`.
