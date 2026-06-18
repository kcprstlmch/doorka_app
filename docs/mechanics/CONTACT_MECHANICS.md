# Contact mechanics 1.2

Ten plik jest zrodlem prawdy dla uproszczonej mechaniki kontaktow i spotkan.

## Glowna zasada
Aplikacja ma byc szybka w pracy terenowej.
Agent nie wybiera wielu roboczych statusow i nie prowadzi rozbudowanej klasyfikacji kontaktu podczas umawiania.

Rdzen mechaniki:
- Umow spotkanie
- Dodaj kontakt
- Usun kontakt

Usuwamy z aktywnej mechaniki:
- Kontakt roboczy
- Do podjechania
- Do przedzwonienia
- Szybkie akcje prowadzone osobnymi statusami

Stare rekordy z tymi statusami powinny byc traktowane jako zwykly `contact`.

## Typy pracy

### Umow spotkanie
Tworzy kontakt ze statusem `scheduled_meeting`.
Spotkanie musi miec:
- dane kontaktu,
- adres,
- date,
- godzine.

Telefon nie jest wymagany.
Notatka jest zwykla notatka wpisana przez agenta.
Aplikacja nie dopisuje automatycznie danych kontaktu do notatki.

Umowione spotkanie:
- pokazuje sie w sekcji Umowione spotkania na Dashboardzie,
- nie pokazuje sie jako zwykly kontakt w sekcji zebranych kontaktow,
- liczy sie do celu dnia wedlug faktycznej daty spotkania zapisanej w bazie, a nie wedlug tego, ile razy agent kliknal Start.

### Dodaj kontakt
Tworzy kontakt ze statusem `contact`.
Kontakt jest prostym zapisem sprawy, osoby albo leada, do ktorego agent chce wrocic.

Kontakt powinien miec przynajmniej jedna informacje pozwalajaca go rozpoznac:
- dane kontaktu,
- telefon,
- adres,
- notatke.

Kontakt pokazuje sie w sekcji kontaktow.
Nie jest umowionym spotkaniem.

### Usun kontakt
Agent moze usunac kontakt z listy.
Na Dashboardzie kontakt mozna usunac gestem przesuniecia w lewo.

## Aktualne statusy
Statusy uzywane przez aplikacje:
- `contact` - zwykly kontakt
- `scheduled_meeting` - umowione spotkanie
- `meeting_active` - spotkanie trwa
- `meeting_done` - spotkanie odbyte
- `signed_contract` - spisana umowa
- `interested` - zainteresowany
- `not_interested` - niezainteresowany
- `no_contact` - brak kontaktu
- `postponed` - przelozone spotkanie

`postponed` jest stanem spotkania, a nie osobnym typem leada.

## Liczniki
Cel dnia umawiania spotkan liczy umowione spotkania po rekordach `scheduled_meeting` z konkretna data spotkania.
Klikniecie Start nie powinno samo decydowac o liczbie umowionych spotkan.

Aktywny kafelek pokazuje:
`Obecny cel: X/Y | Kontakty: Z | 00:00:00`

Kontakty sa liczone osobno od umowionych spotkan.
Kontakt nie dubluje wyniku umowionego spotkania.

## Dashboard
Aktywny kafelek ma byc prosty.
Po rozpoczeciu dnia agent ma miec szybki dostep do:
- Umow spotkanie
- Dodaj kontakt

Nie ma osobnych szybkich akcji:
- podjazd,
- telefon pozniej,
- kontakt roboczy,
- szybka notatka jako czesc mechaniki kontaktu.

## Nieprzerobione spotkania
Nieprzerobione spotkania sa dostepne w Ustawieniach jako osobna lista.
To miejsce na spotkania, ktore wymagaja decyzji albo rozliczenia, ale nie powinny zasmiecac glownego dashboardu.

Na liste trafiaja:
- przeszle `scheduled_meeting`, czyli umowione spotkania z data w przeszlosci bez wyniku,
- `meeting_active`, czyli spotkania rozpoczete, ale niedomkniete wynikiem,
- `postponed`, czyli spotkania przelozone bez ponownego ustawienia normalnego terminu.

Po kliknieciu pozycji agent otwiera szczegoly kontaktu/spotkania i moze je rozliczyc.
To jest bufor porzadkujacy prace agenta, a nie nowy status kontaktu.

## Spotkanie
Spotkanie moze przejsc przez:
- `scheduled_meeting`
- `meeting_active`
- `meeting_done`
- `signed_contract`, `interested` albo `not_interested`

Przelozenie spotkania nie tworzy nowego leada dla tego samego kontaktu.
Po ustaleniu nowej daty kontakt wraca do `scheduled_meeting`.

## Notatki
Notatka jest tylko tekstem wpisanym przez agenta.
Aplikacja nie laczy automatycznie danych kontaktu, adresu i telefonu w pole notatki.

## Baza danych
W bazie status `contact` zastapil dawne:
- `quick_contact`
- `to_visit`
- `to_call`
- `visit_required`

Migracje i normalizacja danych powinny mapowac te stare wartosci do `contact`.

## Optymalizacja kodu
Mechanika 1.2 zostala uproszczona produktowo, ale kod nadal mozna oczyscic po poprzedniej, bardziej rozbudowanej wersji.

Najwiekszy potencjal optymalizacji:
- rozdzielenie duzego `lib/main.dart` na osobne pliki dla Dashboardu, Kontaktow, Ustawien i wspolnych komponentow,
- wyciagniecie zapytan Supabase do prostych serwisow zamiast trzymania ich bezposrednio w widgetach,
- ujednolicenie filtrow kontaktow i spotkan w jednym miejscu, zeby Dashboard, Kontakty i Ustawienia liczyly tak samo,
- usuniecie pozostalosci po starych mechanikach, jesli nie sa juz potrzebne nawet jako migracje,
- wprowadzenie prostych helperow dla pustych stanow, kafelkow i list, zeby nie kopiowac tego samego ukladu.

Realnie mozna zoptymalizowac okolo 60-70% struktury kodu bez zmiany wygladu aplikacji.
To nie znaczy, ze 70% kodu trzeba usunac, tylko ze tyle obecnego balaganu organizacyjnego da sie uporzadkowac.
Najbezpieczniej robic to etapami:
- najpierw porzadek w modelach i statusach,
- potem Dashboard,
- potem Kontakty,
- potem Ustawienia,
- na koncu wspolne komponenty i serwisy.
