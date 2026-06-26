# Decyzje projektowe

Ten plik zapisuje aktualne decyzje produktowe i techniczne, które doprecyzowują pozostałe dokumenty w folderze docs.

## Nadrzędność dokumentacji
Pliki `.md` w folderze `/docs` są podstawą tworzenia obecnej aplikacji Flutter.
Każda implementacja powinna być zgodna z dokumentacją, a nie tylko z istniejącą aplikacją webową.
Jeżeli istniejący projekt `/Users/kacstelmach/crm` ma inne nazwy, statusy, procesy albo uproszczenia niż dokumenty w `/docs`, to decyzje z dokumentacji mają pierwszeństwo.
Rozbieżności zapisujemy w `QUESTIONS.md`, `I_DONT_KNOW.md`, `LATER.md` albo w osobnym pliku audytu, zamiast bezrefleksyjnie przenosić je do Fluttera.

## Istniejąca aplikacja
Na stronie doorka.pl działa już aplikacja Doorka.
Projekt Supabase istnieje i nazywa się "CRM - agent sprzedazowy".
Przed tworzeniem nowych migracji trzeba najpierw zrobić audyt istniejącej aplikacji, obecnego schematu Supabase, tabel, danych i RLS.
Nie tworzymy lokalnych migracji w ciemno, jeśli można pracować bezpośrednio na istniejącym projekcie.
Lokalny folder istniejącej aplikacji webowej znajduje się w `/Users/kacstelmach/crm`.
Projekt `/crm` traktujemy jako źródło technicznego kontekstu, ale dokumentacja w `/docs` jest nadrzędna produktowo.
Nie przepisujemy webowej aplikacji 1:1 do Fluttera.
Przenosimy tylko sprawdzone elementy: assety marki, logikę Supabase, istniejące tabele jako punkt audytu, auth, storage oraz procesy zgodne z aktualną dokumentacją.
Flutter ma od początku korzystać z tej samej produkcyjnej bazy Supabase co doorka.pl.
Baza doorka.pl ma zostać docelowo dostosowana do statusów, danych i procesów zapisanych w `/docs`.
Zmiany struktury i czyszczenie danych wymagają ostrożności, ponieważ część danych w bazie jest do zachowania.
Konta agentów innych niż konto właściciela oraz większość danych testowych są prawdopodobnie do usunięcia, ale przed usunięciem trzeba przygotować listę i potwierdzić zakres.

## Porządkowanie tabel Supabase
Na etap 1 upraszczamy bazę Supabase.
W schemacie `public` zostają tylko tabele `profiles`, `contacts` i `clients`.
Nie tworzymy teraz osobnych tabel dla produktów, dokumentów, statusów ani historii statusów.
Stare tabele z webowego CRM traktujemy jako do audytu albo zastąpienia, ale ich usunięcie wymaga osobnej decyzji i osobnego skryptu destrukcyjnego.
Nowe zmiany SQL do ręcznego uruchomienia w Supabase SQL Editor zapisujemy jako osobne migracje w `docs/sql/migrations/`.
`docs/SQL.md` opisuje model danych i historyczny kontekst, ale nie powinien być miejscem dopisywania kolejnych dużych resetów.
Skrypty czyszczące dane trzymamy tylko w `docs/sql/destructive/` i uruchamiamy po osobnej zgodzie.

## Zakres użytkowników
Obecnie aplikacja jest projektowana dla pojedynczych agentów sprzedaży bezpośredniej.
Panel firmowy, managerski albo widok wielu agentów nie jest aktualnym zakresem prac.
W przyszłości mogą pojawić się konta typu moderator i manager.
Moderator może mieć dostęp do wybranych danych klientów i zmieniać statusy realizacji.
Manager może mieć dostęp do statystyk agentów oraz wybranych danych o kontaktach, jeśli taki zakres zostanie zaprojektowany.

## Rejestracja
Agent może samodzielnie utworzyć konto w aplikacji.
Na teraz do rejestracji konta wymagane są tylko e-mail i hasło.
Nie wymagamy imienia, nazwiska, telefonu ani innych danych profilu na etapie rejestracji.
Po rejestracji agent musi potwierdzić adres e-mail przed wejściem do aplikacji.
Agent pozostaje zalogowany, dopóki sam się nie wyloguje.
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło. Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.

## Sekcje aplikacji
Nowym rdzeniem aplikacji jest dzienniczek cyklu zycia kontaktu.
Pierwsze trzy sekcje aplikacji to:
- Kontakty / Zebrane leady
- Umowione spotkania
- W realizacji

Dashboard przestaje byc glownym pierwszym ekranem pracy agenta.
Najwazniejszy przeplyw to przechodzenie rekordu przez trzy etapy:
`Kontakty` -> `Umowione spotkania` -> `W realizacji`.

Zamknięte decyzje dotyczące głównych sekcji znajdują się w folderze `docs/sections/`:
- Kontakty: `docs/sections/Contacts.md`
- W realizacji: `docs/sections/In_process.md`
- Statystyka: `docs/sections/Statistics.md`
- Dashboard: `docs/sections/Dashboard.md`
- Ustawienia: `docs/sections/Settings.md`

## Supabase
Nazwy statusów, etapy realizacji i ewentualne zmiany struktury danych w Supabase mogą zostać nadpisane dopiero po wyraźnej zgodzie użytkownika.
Na etapie projektowania i zmian UI nie wykonujemy automatycznie migracji ani nadpisywania danych w Supabase.

## Aktywność
Na etap 1 nie tworzymy osobnych tabel historii statusów.
Aktualny status trzymamy bezpośrednio w rekordzie kontaktu albo klienta.
Własne statusy robocze agenta są na tym etapie warstwą UX zapisywaną jako preferencja aplikacji.
Docelowo mogą zostać przeniesione do osobnej tabeli Supabase, jeśli będzie potrzebna synchronizacja między urządzeniami.

Typ kontaktu jest osobną etykietą od statusu.
Typ kontaktu jest wybierany z listy tworzonej w Ustawieniach i zapisuje się automatycznie po wyborze.
W zakładce Kontakty domyślnie widoczne są tylko statusy Do przedzwonienia i Do podjechania; pozostałe statusy agent dodaje w Ustawieniach.

Po zakończeniu cyklu pracy niedomknięte rekordy powinny trafić do Archiwum w Ustawieniach.
Archiwum cyklu jest miejscem porządkowym, a nie główną sekcją pracy agenta.

## Regulamin i polityka prywatności
Na teraz rejestracja nie wymaga osobnego checkboxa regulaminu ani polityki prywatności.
Dokumenty regulaminu i polityki prywatności będą opracowywane w osobnych wątkach.

## Usunięcie konta
Agent może sam usunąć konto, ale wymaga to potwierdzenia przez e-mail.
Z perspektywy aplikacji konto znika od razu po usunięciu.
Technicznie w bazie danych konto może mieć 30 dni karencji, ale agent nie powinien widzieć tej informacji w aplikacji.

## Widoki list
Decyzje dotyczące mechaniki list kontaktów i W realizacji znajdują się w `docs/sections/Contacts.md` oraz `docs/sections/In_process.md`.
Decyzje dotyczące wyglądu list i kafelków znajdują się w `docs/appereance/UX_UI.md` oraz `docs/appereance/design.md`.

## Usuwanie danych
Kontakt może zostać usunięty bezpośrednio z listy po potwierdzeniu popupem.
Przy usuwaniu aplikacja pokazuje popup potwierdzający. Nie wymagamy wpisywania słowa USUŃ.
W głównej liście kontaktów przesunięcie w lewo odsłania tylko przycisk Usuń, ale sama czynność przesunięcia nie usuwa kontaktu.
Przesunięcie w prawo odsłania dodanie do W realizacji.
Każda akcja odsłonięta przez przesunięcie wymaga potwierdzenia.

## Przypomnienia
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Użytkownik może wybrać Przypomnij później za 15 minut, maksymalnie.

## Mapy
Przy adresie ma być przycisk otwarcia zewnętrznej mapy, żeby agent mógł szybko uruchomić nawigację do klienta bez ręcznego wpisywania adresu.

## Offline i online
Głównym źródłem danych aplikacji jest Supabase.
Tryb offline jest wymaganiem docelowym, ale jego dokładny zakres techniczny nie jest jeszcze przesądzony.
Założenie produktowe: jeśli agent straci internet, powinien móc dalej aktualizować dane klientów, kontaktów i statusów, a po odzyskaniu połączenia aplikacja ma automatycznie zsynchronizować zmiany z Supabase.
Aplikacja nie ma przechowywać danych statycznie jako głównego źródła prawdy. Lokalna pamięć służy tylko jako cache/kolejka zmian na czas braku internetu.
Na teraz zakładamy, że internet jest dostępny. Szczegółowy projekt trybu offline zostaje odłożony do późniejszej decyzji.

## Funkcje przyszłościowe
Mapa, teren pracy oraz nagrywanie są funkcjami przyszłościowymi.
Nie wchodzą w aktualny podstawowy zakres aplikacji.

## Model płatności
Model płatności, wersji bezpłatnej i wersji Premium nie jest jeszcze ustalony.
Na ten moment aplikacja ma być projektowana jako jedna całość funkcjonalna, bez rozdzielania funkcji na darmowe i płatne.

## Platformy
Aktualnym priorytetem jest Flutter na iOS i Android.
Panel webowy app.doorka.pl może zostać rozważony później.
UX/UI projektujemy pod telefon i tablet.
Duże ekrany desktopowe nie są aktualnym zakresem aplikacji; Chrome/macOS służą tylko jako techniczny podgląd podczas pracy.

## Język
Na ten moment aplikacja jest projektowana wyłącznie po polsku.
Rynek zagraniczny i inne języki mogą zostać rozważone później.
