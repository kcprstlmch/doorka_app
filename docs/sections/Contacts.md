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
Kontakt ma dwa poziomy logiki:
- etap systemowy,
- status roboczy agenta.

Etap systemowy decyduje, gdzie rekord jest widoczny w aplikacji:
- Kontakty,
- Umówione spotkania,
- W realizacji.

Status roboczy agenta opisuje sytuację w ramach etapu `Kontakty`.
Domyślnie kontakt nie musi mieć statusu roboczego.
Brak statusu kontaktu jest zapisywany w SQL jako `NULL` w polu `contacts.contact_status`.

Statusy robocze agent dodaje i edytuje w Ustawieniach.
Status roboczy ma nazwę i kolor nadawany automatycznie przez system.
Statusy pojawiają się później w polu Status w formularzu kontaktu.
Kliknięcie pola Status w szczegółach kontaktu otwiera popup wyboru statusu.
W popupie wyboru statusu agent może też kliknąć `Dodaj status`, jeśli brakuje mu właściwej opcji.

Status techniczny `contact` nadal może istnieć w danych jako zwykły kontakt, ale nie musi być pokazywany agentowi jako wybieralny status.

## Typy kontaktu
Typy kontaktu są osobną warstwą od statusu i działają jak tagi/karteczki.
Jeden kontakt może mieć wiele typów jednocześnie, np. `karteczki`, `VOTUM`, `świadczenia zdrowotne`.

W kafelku kontaktu w sekcji Kontakty obok nazwy kontaktu aplikacja pokazuje tylko kolorowe kropki przypisanych typów.
Nazwy typów nie są pokazywane na kafelku, żeby lista była lekka i szybka do skanowania.
Przykład: jeśli typ `PRO-NETWORK` ma kolor zielony, na kafelku widać tylko zieloną kropkę.
Jeśli kontakt ma drugi typ, obok zielonej kropki pojawia się kolejna kropka w kolorze drugiego typu.
Kliknięcie kropki w sekcji Kontakty pokazuje nad kropką mały podpis z nazwą typu.

Pełne nazwy typów są widoczne dopiero po wejściu w szczegóły kontaktu.
W szczegółach kontaktu nazwy typów są pokazywane pod przyciskami `Nawiguj` i `Zadzwoń`.
W szczegółach kontaktu agent widzi aktywne typy oraz mały przycisk `+`.
Kliknięcie `+` otwiera listę typów utworzonych w ustawieniach, np. `karteczki`, `VOTUM`, `PRO-NETWORK`, `dotacja`.
Agent może zaznaczać albo odznaczać typy kontaktu po kolei z tej listy.
Jeden kontakt może mieć maksymalnie 3 aktywne typy jednocześnie.
Po wybraniu 3 typów przycisk `+` znika.
Dłuższe przytrzymanie aktywnego typu kontaktu ponownie otwiera listę wyboru typów.
Zmiana typów zapisuje się automatycznie, bez klikania `Zapisz zmiany`.

Typy kontaktu nie są pokazywane w sekcji Umówione spotkania.

## Spotkanie
Spotkanie zaczyna sie jako `scheduled_meeting`.
W szczegółach umówionego spotkania agent widzi cztery szybkie kwadraty akcji w jednym rzędzie:
- Sprzedane - zielony kwadrat z ptaszkiem
- Nie sprzedane - żółty kwadrat z trójkątem ostrzegawczym
- Przełożone - niebieski kwadrat ze strzałką w bok
- Nieodbyte - spotkanie się nie odbyło

Sprzedane może przenieść kontakt do W realizacji.
Nie sprzedane pyta najpierw o powód, a potem o wnioski na przyszłość. Po tym agent wybiera `Zapamiętaj spotkanie` albo `Wróć do kontaktów`.
`Czeka na decyzję` nie jest osobnym przyciskiem. Jest powodem w akcji `Nie sprzedane`, żeby agent nie traktował czekania jako samodzielnego wyniku spotkania.
Po wyborze powodu `Czeka na decyzję` aplikacja wymaga ustawienia terminu powrotu do klienta.
Przełożone pyta o nowy termin. Jeśli termin jest znany, spotkanie zostaje w Umówionych spotkaniach z nową datą. Jeśli termin nie jest znany, rekord wraca do Kontaktów jako `Do przedzwonienia` i trafia do przypomnień.
Nieodbyte pyta `Przekładamy?`. Jeśli tak, agent wybiera nowy termin umówionego spotkania. Jeśli nie, aplikacja pyta `Co robimy?` i agent wybiera `Usuń` albo `Zapamiętaj spotkanie`.

Nieodbyte spotkanie, np. klient nie odebrał telefonu, nie jest tym samym co `Niezainteresowany`.
Niezainteresowany / beton / zła relacja może być usuwany, bo taki kontakt nie powinien zaśmiecać pracy agenta.

## Przelozone
`postponed` oznacza przelozone spotkanie.
To nadal jest mechanika spotkania, a nie nowy typ kontaktu.
Przelozenie nie powinno dublowac wyniku leada dla tego samego kontaktu.

## Archiwum cyklu
Po zakończeniu cyklu pracy, np. kolejnego dnia, rekordy bez oznaczonego wyniku powinny trafić do archiwum w Ustawieniach.
Archiwum w Ustawieniach ma pokazywać elementy, które nie zostały domknięte w cyklu:
- umówione spotkania bez wybranego wyniku,
- kontakty wymagające dalszej decyzji,
- inne rekordy, których agent nie oznaczył w trakcie cyklu.
