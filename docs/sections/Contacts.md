# Contacts

Ten plik jest zrodlem prawdy dla sekcji Kontakty.
Opisuje aktualna, uproszczona mechanike kontaktow przed przeniesieniem do W realizacji.

## Rola sekcji
Kontakt jest prostym obiektem pracy agenta.
Agent moze:
- dodac kontakt,
- edytowac kontakt,
- umowic spotkanie,
- rozpoczac i rozliczyc spotkanie,
- usunac kontakt,
- przeniesc podpisana umowe do W realizacji.

## Podstawowe dane kontaktu
Kontakt moze zawierac:
- dane kontaktu,
- numer telefonu,
- adres,
- status,
- uwagi / notatki.

Notatka jest tylko tekstem wpisanym przez agenta.
Aplikacja nie dopisuje do notatki automatycznie danych kontaktowych.

## Dodaj kontakt
Akcja Dodaj kontakt tworzy rekord ze statusem `contact`.
Kontakt powinien miec przynajmniej jedna informacje rozpoznawcza:
- dane kontaktu,
- telefon,
- adres,
- notatke.

To jest zwykly kontakt, a nie umowione spotkanie.

## Umow spotkanie
Akcja Umow spotkanie tworzy rekord ze statusem `scheduled_meeting`.
Umowione spotkanie musi miec:
- dane kontaktu,
- adres,
- date,
- godzine.

Telefon nie jest wymagany.
Umowione spotkania sa pokazywane na Dashboardzie w sekcji Umowione spotkania.
Nie sa pokazywane jako zwykle kontakty w sekcji zebranych kontaktow.

## Usun kontakt
Kontakt mozna usunac z listy.
Na Dashboardzie usuwanie kontaktu odbywa sie przez przesuniecie kafelka w lewo.

## Statusy
Aktywne statusy kontaktow:
- `contact` - zwykly kontakt
- `scheduled_meeting` - umowione spotkanie
- `meeting_active` - spotkanie trwa
- `meeting_done` - spotkanie odbyte
- `signed_contract` - spisana umowa
- `interested` - zainteresowany
- `not_interested` - niezainteresowany
- `no_contact` - brak kontaktu
- `postponed` - przelozone spotkanie

Nie uzywamy juz osobnych statusow:
- Kontakt roboczy
- Do podjechania
- Do przedzwonienia

Stare dane z tymi statusami sa traktowane jako `contact`.

## Spotkanie
Spotkanie zaczyna sie jako `scheduled_meeting`.
Po kliknieciu Start spotkania przechodzi w `meeting_active`.
Po zakonczeniu agent wybiera wynik:
- Spisana umowa
- Zainteresowany
- Nie zainteresowany

Spisana umowa moze zostac przeniesiona do W realizacji.
Zainteresowany zostaje jako kontakt do dalszej pracy.
Nie zainteresowany moze zostac zamkniety albo archiwizowany zgodnie z dalsza logika aplikacji.

## Przelozone
`postponed` oznacza przelozone spotkanie.
To nadal jest mechanika spotkania, a nie nowy typ kontaktu.
Przelozenie nie powinno dublowac wyniku leada dla tego samego kontaktu.

## Nieprzerobione spotkania
Nieprzerobione spotkania sa lista pomocnicza w Ustawieniach.
Nie tworza nowego statusu.

Na liste trafiaja spotkania, ktore wymagaja rozliczenia:
- przeszle `scheduled_meeting`,
- `meeting_active`,
- `postponed`.

Po kliknieciu takiego spotkania agent otwiera szczegoly kontaktu i moze je domknac.
