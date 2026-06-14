# Audyt istniejącej aplikacji CRM

Ten plik opisuje, co przenosimy koncepcyjnie z istniejącego lokalnego projektu `/Users/kacstelmach/crm` do aplikacji Flutter w `/Users/kacstelmach/doorka`.
Dokumentacja w `/docs` pozostaje nadrzędnym źródłem prawdy, jeśli istniejący kod webowy różni się od aktualnych decyzji produktowych.
Oznacza to, że projekt `/crm` pomaga nam szybciej zrozumieć działające rozwiązania, ale nie decyduje samodzielnie o docelowej aplikacji mobilnej.

## Źródło
Istniejący projekt lokalny znajduje się w folderze `/Users/kacstelmach/crm`.
Jest to aplikacja webowa oparta o Next.js, React i Supabase.
Projekt zawiera działające elementy logowania, listy kontaktów, klientów, raportów, managerów, plików klienta, nagrań i kalkulatora.

## Co przenosimy do Fluttera
- assety marki: `d2d-door-ka-logo.png` oraz `app-sidebar-logo.png`
- ogólną konfigurację połączenia z tym samym projektem Supabase, ale bez kopiowania sekretów do kodu źródłowego
- założenie, że Supabase Auth odpowiada za logowanie, rejestrację, sesję użytkownika i reset hasła
- istniejące nazwy tabel jako punkt audytu bazy danych
- logikę przypisania danych do użytkownika Supabase
- ideę aktywności jako historii działań/statusów
- ideę osobnego storage dla plików klienta
- część kolorystyki i stylu jako inspirację wizualną, dopóki nie ustalimy finalnego UX/UI

## Co wymaga dostosowania do dokumentacji
Istniejący projekt webowy używa starszego uproszczenia statusów kontaktów:
- `contact`
- `lead`
- `client`
- `lost`

Docelowa aplikacja według dokumentacji używa konkretnych statusów kontaktów:
- Umówione spotkanie
- Zainteresowany
- Szybki kontakt
- Spisana umowa
- Do podjechania
- Do przedzwonienia
- Niezainteresowany
- Brak kontaktu

Istniejący projekt webowy zapisuje klientów w tabeli `crm_leads`.
Według aktualnej dokumentacji sekcja Moi Klienci ma być osobną sekcją i osobną tabelą klientów, a nie tylko kolejnym statusem kontaktu.
Dlatego przed implementacją Fluttera trzeba ustalić, czy aktualną tabelę `crm_leads` traktujemy jako docelową tabelę klientów, czy migrujemy ją do nowej, czytelniejszej struktury.

## Istniejące elementy Supabase wykryte w projekcie `/crm`
- `contacts`
- `activities`
- `crm_leads`
- `crm_profiles`
- `crm_manager_agents`
- `crm_recruitment_stats`
- `crm_recordings`
- `calculator_states`
- bucket storage `crm-client-files`

## Stan przed zmianą: pola i statusy

Ta sekcja zapisuje stan obecnej aplikacji webowej przed porządkowaniem tabel Supabase.
To jest punkt odniesienia do migracji, a nie docelowy model aplikacji.

## Istniejące pola kontaktu w projekcie `/crm`
Tabela kontaktów jest używana pod nazwą `contacts`.
Aktualnie aplikacja webowa pracuje na polach:
- `id`
- `first_name`
- `last_name`
- `phone`
- `address`
- `note`
- `status`
- `lead_day`
- `lead_time`
- `user_id`
- `created_at`
- `updated_at`

Istniejące statusy kontaktów w projekcie `/crm`:
- `contact` - Kontakt
- `lead` - Lead
- `client` - Sprzedane
- `lost` - Spad

Powiązana tabela `activities` zawiera aktywności kontaktu:
- `id`
- `contact_id`
- `type`
- `note`
- `created_at`

## Istniejące pola klientów w projekcie `/crm`
Tabela `crm_leads` zawiera dane, które częściowo odpowiadają sekcji Moi Klienci:
- `id`
- `name`
- `residential_address`
- `installation_address`
- `installation_address_same_as_residential`
- `phone`
- `email`
- `installation_photo_names`
- `credit_agreement_file_names`
- `status`
- `payment_method`
- `net_amount`
- `gross_amount`
- `vat_rate`
- `markup`
- `commission`
- `client_own_contribution`
- `additional_costs`
- `source`
- `created_at`

Istniejące statusy realizacji klienta w projekcie `/crm`:
- `zaliczka` - Zaliczka
- `umowa_kredytowa_zatwierdzona` - Umowa kredytowa zatwierdzona
- `montaz_umowiony` - Montaż umówiony
- `zamontowany` - Zamontowany
- `zgloszony_do_ze` - Zgłoszony do ZE
- `zgloszona_dotacja` - Zgłoszona dotacja
- `otrzymana_dotacja` - Otrzymana dotacja

Według dokumentacji docelowe statusy realizacji klienta to:
- Spisana umowa
- Zatwierdzone finansowanie
- Wpłacona część płatności
- W trakcie montażu
- Zamontowany
- Zgłoszony do ZE
- Zgłoszona dotacje
- Spad

## Auth
Istniejąca aplikacja webowa ma:
- logowanie e-mail/hasło
- rejestrację e-mail/hasło
- komunikat o potwierdzeniu e-mail
- utrzymywanie sesji użytkownika

Według aktualnej dokumentacji Flutter musi dodać albo dopracować:
- reset hasła przez "Nie pamiętasz hasła?"
- docelowe Google Authentication
- akceptację regulaminu i polityki prywatności przy rejestracji
- obsługę usunięcia konta z potwierdzeniem e-mail

## Manager i role
Istniejący projekt zawiera plik SQL dla managerów i agentów.
Wykryte są role:
- agent
- manager
- admin

To jest zgodne z kierunkiem przyszłościowym, ale aktualny podstawowy zakres aplikacji dotyczy pojedynczego agenta.
Nie przenosimy panelu managerskiego jako pierwszego modułu Fluttera, ale zachowujemy go jako ważny kontekst przyszłej architektury.

## Czego nie przenosimy teraz
- kodu Next.js i React jako kodu aplikacji mobilnej
- katalogów `node_modules` i `.next`
- modułu kalkulatora, ponieważ kalkulator ma zostać usunięty z aktualnego zakresu
- modułu nagrań jako podstawowego zakresu, ponieważ nagrania są funkcją przyszłościową
- twardo wpisanych kluczy Supabase do kodu Fluttera
- starszej listy statusów kontaktów z aplikacji webowej bez mapowania na aktualną dokumentację

## Assety przeniesione do Fluttera
Do projektu Flutter zostały przeniesione:
- `assets/images/d2d-door-ka-logo.png`
- `assets/images/app-sidebar-logo.png`

Pliki zostały dodane do `pubspec.yaml`.

## Najważniejsze ryzyka
- Istniejąca tabela `crm_leads` może mieszać pojęcie klienta, leada i produktu.
- Aktualna dokumentacja wymaga osobnych Kontaktów i Moi Klienci, więc trzeba uważać, aby nie odtworzyć starego uproszczenia.
- W projekcie webowym istnieją elementy przyszłościowe, które mogą rozpraszać pierwszy etap Fluttera.
- Dane Supabase muszą zostać sprawdzone przed zmianami strukturalnymi, ponieważ działająca aplikacja istnieje już na doorka.pl.
- Klucze i konfiguracja Supabase muszą być przeniesione bezpiecznie, bez zapisywania sekretów w publicznym kodzie.

## Wniosek
Najlepszy kierunek to nie przepisywać aplikacji webowej 1:1.
Trzeba użyć jej jako źródła działającej logiki, nazw tabel i assetów, a Fluttera budować zgodnie z aktualnymi dokumentami `/docs`.

## Decyzje po audycie
Flutter ma korzystać z tej samej produkcyjnej bazy Supabase co doorka.pl.
Docelowo baza doorka.pl ma zostać zaktualizowana do statusów, danych i procesów z dokumentacji `/docs`.
Docelowa tabela sekcji Moi Klienci ma nazywać się `clients`.
Istniejąca tabela `crm_leads` zostaje potraktowana jako stara tabela do migracji albo zastąpienia.
Na etap 1 upraszczamy schemat `public` do tabel `profiles`, `contacts` i `clients`.
Stare tabele CRM, managerów, nagrań, kalkulatora, aktywności i rekrutacji nie są częścią aktualnego modelu.
Dotychczasowe kontakty i klienci mogą zostać wyczyszczeni.
Konto `kcprstlmch@gmail.com` zostaje kontem admina.
