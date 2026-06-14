# Plan współpracy

Ten plik służy do rozmów o kolejności pracy, obowiązkach, decyzjach i podziale zadań między użytkownika a Codex.

## Zasada pracy
Budujemy aplikację etapami.
Każdy etap powinien mieć:
- cel,
- konkretne zadania,
- decyzje po stronie użytkownika,
- rzeczy, które może wykonać Codex,
- wynik końcowy.

Pliki `.md` w folderze `/docs` są podstawą rozmowy i implementacji.
Jeśli w trakcie pracy pojawi się konflikt między starym projektem `/crm` a dokumentacją, najpierw opieramy się na `/docs`, a konflikt zapisujemy do pytań lub decyzji.

## Etap 1: Supabase schema + RLS

### Cel
Sprawdzić i uporządkować fundament danych istniejącej aplikacji.
Supabase ma być głównym źródłem prawdy dla kontaktów, klientów, statusów, aktywności, dokumentów i statystyk.
Każdy agent widzi tylko swoje dane.
Na stronie doorka.pl działa już aplikacja Doorka, a projekt Supabase istnieje pod nazwą "CRM - agent sprzedazowy".

### Know-how
Najpierw trzeba zrobić audyt istniejącego projektu Supabase, zanim zaczniemy tworzyć nowe tabele, migracje albo zmiany.
Nie projektujemy bazy w ciemno od zera, jeśli istnieją już tabele, dane i działająca aplikacja.
Każda tabela z danymi agenta powinna mieć `agent_id`.
RLS musi pilnować, żeby agent mógł czytać i edytować tylko swoje rekordy.
Tabele powinny odzwierciedlać decyzje z `DATA_MODEL.md`.

### Zadania Codex
- Sprawdzić obecny schemat Supabase, jeśli użytkownik udostępni dostęp albo eksport struktury.
- Porównać istniejące tabele z `DATA_MODEL.md`.
- Wskazać braki, konflikty i ryzyka.
- Zaproponować zmiany w tabelach, indeksach i relacjach.
- Zaproponować lub poprawić polityki RLS.
- Przygotować SQL zmian dopiero po audycie istniejącej struktury.
- Nie tworzyć lokalnych migracji w ciemno bez potwierdzenia.
- Pilnować zgodności z dokumentami w `/docs`.

### Zadania użytkownika
- Udostępnić sposób dostępu do istniejącego projektu Supabase "CRM - agent sprzedazowy" albo eksport schematu.
- Potwierdzić, czy Codex ma pracować przez panel Supabase, SQL Editor, MCP/narzędzie, connection string, czy tylko na podstawie eksportu.
- Nie podawać publicznie sekretów w dokumentacji.
- Potwierdzić każdą zmianę struktury bazy przed wykonaniem na działającej aplikacji.
- Przed czyszczeniem danych wskazać, które dane i konta są do zachowania, a które można usunąć.

### Wynik końcowy
Zweryfikowany istniejący schemat Supabase, lista braków względem docelowej aplikacji i bezpieczny plan zmian bez ryzyka popsucia działającej aplikacji.

### Aktualizacja po odnalezieniu folderu `/crm`
Lokalny folder istniejącej aplikacji webowej znajduje się w `/Users/kacstelmach/crm`.
W projekcie wykryto działającą aplikację Next.js z Supabase.
Do Fluttera przeniesiono assety marki:
- `assets/images/d2d-door-ka-logo.png`
- `assets/images/app-sidebar-logo.png`

Powstał plik `EXISTING_CRM_AUDIT.md`, który opisuje, co z istniejącego projektu traktujemy jako techniczną referencję.
Najważniejszy wniosek: nie przepisujemy aplikacji webowej 1:1.
Flutter ma korzystać z istniejącej wiedzy i Supabase, ale działać zgodnie z dokumentacją `/docs`.

#### Zadania Codex po audycie `/crm`
- Sprawdzić, czy tabela `crm_leads` może być docelowo tabelą Moi Klienci.
- Sprawdzić polityki RLS dla `contacts`, `activities`, `crm_leads` i storage `crm-client-files`.
- Przygotować mapowanie starych statusów webowej aplikacji na statusy z aktualnej dokumentacji.
- Przygotować bezpieczną konfigurację Supabase dla Fluttera bez wpisywania sekretów w kod.
- Zacząć od logowania i podstawowego szkieletu aplikacji mobilnej.

#### Zadania użytkownika po audycie `/crm`
- W osobnym wątku omówić docelowy porządek tabel Supabase, w tym `crm_leads` i strukturę Moi Klienci.
- Przy przeglądzie danych wskazać rekordy niewyrzucalne oraz dane testowe do usunięcia.

#### Ustalenia
- Flutter ma od początku korzystać z tej samej produkcyjnej bazy Supabase co doorka.pl.
- Baza doorka.pl ma zostać zaktualizowana do statusów i danych zapisanych w dokumentacji `/docs`.
- Temat tabel Supabase, szczególnie `crm_leads`, został wydzielony do osobnego wątku.
- W bazie są dane niewyrzucalne oraz dane testowe, w tym prawdopodobnie większość agentów poza właścicielem, które będą do usunięcia po przeglądzie.

## Etap 2: Logowanie i rejestracja

### Cel
Agent może założyć konto, potwierdzić e-mail, zalogować się, pozostać zalogowanym oraz zresetować hasło.

### Know-how
Logowanie powinno bazować na Supabase Auth.
Podstawowa rejestracja to e-mail i hasło.
Google Authentication ma być docelowo wspierane, ale konfigurację odkładamy na późniejszy etap.
Reset hasła dotyczy tylko kont e-mail/hasło.
Konto Google nie potrzebuje osobnego resetu hasła w aplikacji.

### Zadania Codex
- Dodać zależności Flutter/Supabase.
- Skonfigurować klienta Supabase w aplikacji.
- Zbudować ekrany: logowanie, rejestracja, reset hasła.
- Dodać obsługę sesji użytkownika.
- Dodać komunikaty błędów i stanów ładowania.
- Przygotować logikę rozpoznawania zalogowanego agenta.

### Zadania użytkownika
- Potwierdzić dane projektu Supabase.
- Skonfigurować Google Authentication w Supabase/Google Cloud dopiero wtedy, gdy wrócimy do tego tematu.
- Przygotować lub potwierdzić teksty ekranów logowania/rejestracji.
- Potwierdzić, czy onboarding po rejestracji omawiamy przed wdrożeniem logowania, czy później.

### Wynik końcowy
Agent może bezpiecznie wejść do aplikacji i pracować na danych przypisanych do swojego konta.

## Etap 3: Kontakty

### Cel
Zbudować podstawowy moduł kontaktów, czyli core aplikacji.

### Know-how
Kontakt jest głównym obiektem pracy agenta przed przeniesieniem do Moi Klienci.
Lista kontaktów ma być grupowana po statusach.
Status jest kluczową informacją kontaktu.
Zmiana statusu wymaga zatwierdzenia i zapisuje się w aktywności.
Archiwum kontaktów pozwala ukryć kontakt z aktywnej listy i później go przywrócić.

### Zadania Codex
- Zbudować model kontaktu w Flutterze.
- Zbudować ekran listy kontaktów grupowanej po statusach.
- Zbudować formularz dodawania kontaktu.
- Obsłużyć statusy: Umówione spotkanie, Zainteresowany, Szybki kontakt, Do podjechania, Do przedzwonienia, Niezainteresowany, Brak kontaktu.
- Dodać logikę pól zależnych od statusu.
- Dodać szczegóły kontaktu.
- Dodać zmianę statusu z potwierdzeniem.
- Dodać aktywność statusów.
- Dodać archiwum kontaktów i przywracanie.
- Dodać przycisk dzwonienia i otwarcia mapy z adresu.

### Zadania użytkownika
- Doprecyzować wygląd kafelka kontaktu: jakie dane mają być widoczne na liście.
- Potwierdzić, czy numer telefonu jest widoczny tekstowo, czy tylko jako przycisk.
- Doprecyzować termin dla Do podjechania: kafelki, kalendarz albo oba.
- Doprecyzować znaczenie jakości S/M/L/XL.
- Potwierdzić, czy produkt przy Umówione spotkanie ma być także osobnym polem technicznym.

### Wynik końcowy
Agent może dodawać, przeglądać, filtrować, archiwizować i aktualizować kontakty.

## Etap 4: Moi Klienci

### Cel
Zbudować osobną sekcję i osobną tabelę klientów.

### Know-how
Moi Klienci nie są tylko filtrem kontaktów.
Klient powstaje po kliknięciu Dodaj do Moi Klienci.
Dodanie do Moi Klienci odbywa się przez przesunięcie kontaktu w prawo.
Status realizacji klienta zmienia kolor nagłówka albo całej sekcji klienta.
Status Spad oznacza klienta, który po dodaniu do Moi Klienci rezygnuje.

### Zadania Codex
- Zbudować tabelę i model klienta.
- Zbudować przeniesienie kontaktu do Moi Klienci.
- Zbudować listę Moi Klienci.
- Zbudować szczegóły klienta.
- Dodać statusy realizacji klientów.
- Dodać status Spad i przycisk Przenieś do archiwum.
- Dodać sekcje: dane klienta, umowa, płatność, dokumenty, status realizacji.
- Dodać archiwum klientów.
- Dodać synchronizację wspólnych pól kontaktu i klienta.

### Zadania użytkownika
- Doprecyzować finalny wygląd kafelka klienta.
- Doprecyzować, czy kolor statusu ma być tłem, paskiem, nagłówkiem czy całą sekcją.
- Doprecyzować model wielu produktów jednego klienta.
- Potwierdzić, czy dokumenty trzymamy w Supabase Storage.
- Potwierdzić realny limit plików i kompresję zdjęć.
- Doprecyzować, jak klient wraca do kontaktów, jeśli się rozmyśli.

### Wynik końcowy
Agent może zarządzać klientami po podpisaniu umowy, monitorować realizację i archiwizować klientów.

## Etap 5: Statystyki

### Cel
Zbudować automatyczne statystyki pracy agenta.

### Know-how
Statystyki nie są wpisywane ręcznie.
Są wyliczane z danych w Supabase.
Najważniejsze dane na start to: umówione spotkania, spisane umowy, klienci dodani do Moi Klienci i spady.
Spad liczymy jako konwersję: `(spisana umowa -> Moi Klienci) / status Spad`, pokazane procentowo.
Tydzień zaczyna się w poniedziałek.
Na tym etapie ważniejszy jest sposób wyświetlania statystyk niż finalny zestaw metryk.
Statystyki mają być pokazane jako kafelki, które użytkownik może przestawiać.
Nad kafelkami ma być filtr zakresu danych: łącznie, rok, miesiąc, tydzień i dzień.
Kliknięcie kafelka prowadzi do prostych szczegółów danej statystyki.
Eksport statystyk ma znajdować się w ustawieniach konta.

### Zadania Codex
- Przygotować zapytania/statystyki z Supabase.
- Zbudować model wyliczeń statystyk.
- Zbudować ekran Statystyka.
- Dodać zakresy: łącznie, rok, miesiąc, tydzień i dzień.
- Dodać przestawialne kafelki statystyk.
- Dodać szczegóły po kliknięciu kafelka.
- Dodać porównania okresów, jeśli zostaną potwierdzone.
- Dodać statystykę spadów.
- Przygotować miejsce na eksport statystyk w ustawieniach konta.

### Zadania użytkownika
- Doprecyzować, czy statystyki mają pokazywać kilka rodzajów konwersji.
- Doprecyzować, czy spad obniża skuteczność agenta.
- Doprecyzować, czy statystyki mają liczyć kontakty zarchiwizowane.
- Doprecyzować zakresy czasu widoczne w aplikacji.

### Wynik końcowy
Agent widzi mierzalny wynik swojej pracy bez ręcznego liczenia.

## Etap 6: Dashboard

### Cel
Zbudować stronę główną aplikacji.

### Know-how
Dashboard powinien pokazywać najważniejsze informacje z istniejących danych.
Nie powinien być projektowany przed kontaktem, klientem i statystykami, bo inaczej będzie tylko pustą makietą.
Aktywny kafelek i UX Dashboardu są jeszcze tematem do późniejszej rozmowy.

### Zadania Codex
- Zbudować ekran Dashboard po powstaniu kontaktów, klientów i statystyk.
- Pokazać dzisiejsze i najbliższe kontakty do zadzwonienia/podjechania.
- Pokazać najważniejsze statystyki.
- Dodać możliwość zmiany godziny spotkania bezpośrednio z Dashboardu.
- Dodać puste stany.

### Zadania użytkownika
- Omówić UX Dashboardu na podstawie inspiracji.
- Doprecyzować aktywny kafelek.
- Doprecyzować, co agent ma zobaczyć jako pierwsze po otwarciu aplikacji.
- Doprecyzować cytaty/komunikaty motywacyjne.

### Wynik końcowy
Agent po wejściu do aplikacji widzi, co ma dzisiaj zrobić i jak idą jego wyniki.

## Etap 7: Sesja leadowania

### Cel
Zbudować funkcję Rozpocznij leadowanie.

### Know-how
Rozpocznij leadowanie uruchamia licznik czasu.
Agent może pauzować sesję.
Cel sesji obejmuje liczbę umówionych spotkań i liczbę zebranych kontaktów.
Zamknij dzień pojawia się wtedy, gdy agent zrealizuje cel danego spotkania/sesji leadowania.

### Zadania Codex
- Zbudować licznik sesji leadowania.
- Dodać pauzę.
- Dodać ustawienie celu sesji.
- Liczyć kontakty i umówione spotkania w trakcie sesji, jeśli zostanie potwierdzone.
- Dodać podsumowanie sesji.
- Przygotować logikę Zamknij dzień.

### Zadania użytkownika
- Doprecyzować ekran ustawiania celu.
- Doprecyzować, czy cel może być domyślny.
- Doprecyzować, czy agent może zakończyć sesję bez osiągnięcia celu.
- Doprecyzować podsumowanie dnia.

### Wynik końcowy
Agent może mierzyć realny czas leadowania i wynik sesji.

## Etap 8: Dokumenty prawne

### Cel
Przygotować regulamin i politykę prywatności przed realnym wypuszczeniem aplikacji.

### Know-how
Te dokumenty nie blokują startu programowania, ale są potrzebne przed testami z prawdziwymi agentami i prawdziwymi danymi klientów.
Osobne wątki zostały utworzone i zapisane w `LEGAL.md`.

### Zadania Codex
- Zadawać pytania w osobnych wątkach.
- Na podstawie odpowiedzi przygotować projekt regulaminu.
- Na podstawie odpowiedzi przygotować projekt polityki prywatności.
- Dopasować dokumenty do faktycznych funkcji aplikacji.

### Zadania użytkownika
- Odpowiadać na pytania w osobnych wątkach.
- Podać dane właściciela/usługodawcy.
- Podać dane kontaktowe.
- Potwierdzić finalny zakres funkcji przed publikacją.
- Skonsultować finalne dokumenty prawnie, jeśli aplikacja będzie publicznie udostępniana.

### Wynik końcowy
Aplikacja ma przygotowane dokumenty prawne wymagane do bezpiecznego testowania i publikacji.

## Rekomendowany pierwszy krok
Najpierw przygotować Supabase schema + RLS.
To jest techniczny fundament aplikacji.
Po zatwierdzeniu schematu można przejść do logowania i kontaktów.
