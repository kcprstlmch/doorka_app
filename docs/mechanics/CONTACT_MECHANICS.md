# Contact mechanics 1.3

Ten plik jest aktualnym zrodlem prawdy dla mechaniki kontaktow, spotkan i realizacji.
Nadpisuje poprzednia uproszczona mechanike 1.2.

## Glowna idea

Aplikacja ma byc dzienniczkiem i systemem prowadzenia handlowca przez zycie kontaktu.
Najwiekszy problem agenta to chaos w kontaktach, umowionych spotkaniach i realizacjach.
Aplikacja ma zarzadzac tym chaosem za agenta przez proste statusy, sekcje i pytania.

Agent ma robic minimum:
- dodac kontakt albo spotkanie,
- odpowiadac na krotkie pytania aplikacji,
- przenosic rekord miedzy etapami wtedy, gdy faktycznie zmienia sie sytuacja.

Celem aplikacji jest zwiekszenie dochodu agenta przez lepsze pilnowanie leadow, spotkan i umow.

## Trzy cykle zycia kontaktu

Kazdy lead/kontakt przechodzi przez maksymalnie trzy glowne cykle:

1. `Kontakt / Lead`
2. `Umowione spotkanie`
3. `W realizacji`

Te cykle sa rownoczesnie glownymi sekcjami aplikacji.

## Sekcje aplikacji

### 1. Kontakty / Zebrane leady

To pierwszy etap zycia kontaktu.
Trafiaja tu osoby, ktore agent pozyskal, ale nie sa jeszcze umowionym spotkaniem.

Przykladowy status techniczny:
- `contact`

Kontakt z tej sekcji moze przejsc tylko do:
- `Umowione spotkania`

Kontakt nie moze przejsc bezposrednio do `W realizacji`.
Najpierw musi stac sie umowionym spotkaniem.

### 2. Umowione spotkania

To drugi etap zycia kontaktu.
Kontakt trafia tu wtedy, gdy agent umowil spotkanie albo chce poprowadzic go jako spotkanie.

Przykladowy status techniczny:
- `scheduled_meeting`

Umowione spotkanie moze przejsc do:
- `Kontakty / Zebrane leady`
- `W realizacji`

Powrot do kontaktow jest potrzebny np. gdy klient odklada temat, nie jest gotowy albo trzeba wrocic do niego pozniej bez aktywnej realizacji.

### 3. W realizacji

To trzeci etap zycia kontaktu.
Kontakt trafia tu wtedy, gdy spotkanie zakonczylo sie realna szansa realizacji, podpisaniem umowy, sprawdzeniem zdolnosci kredytowej albo innym procesem, ktory trzeba doprowadzic dalej.

Przykladowa tabela obecna:
- `clients`

W realizacji moze przejsc do:
- `Umowione spotkania`

Nie przechodzimy bezposrednio z `W realizacji` do `Kontakty / Zebrane leady`.
Jesli realizacja z jakiegos powodu odpada albo trzeba wrocic do klienta za dlugi czas, rekord wraca najpierw do `Umowione spotkania`.

Przyklad:
Klient podpisal umowe, ale zachorowal i instalacja moze ruszyc dopiero za pol roku.
Wtedy agent moze cofnac rekord z `W realizacji` do `Umowione spotkania`, zeby kontakt nie zniknal z procesu.

## Dozwolone przejscia

Dozwolone:
- `Kontakty` -> `Umowione spotkania`
- `Umowione spotkania` -> `Kontakty`
- `Umowione spotkania` -> `W realizacji`
- `W realizacji` -> `Umowione spotkania`

Niedozwolone:
- `Kontakty` -> `W realizacji`
- `W realizacji` -> `Kontakty`

Powod:
Cykl zycia musi byc zachowany.
Lead najpierw musi stac sie spotkaniem, dopiero potem realizacja.
Realizacja wraca najpierw do spotkania, bo nadal dotyczy klienta, z ktorym trzeba ustalic dalszy proces.

## Rola aplikacji

Aplikacja nie ma byc tylko lista kontaktow.
Ma prowadzic agenta i podpowiadac, co zrobic z kontaktem na danym etapie.

Najwazniejsza funkcja aplikacji:
- zarzadzanie kontaktami zamiast agenta,
- prowadzenie przez statusy,
- zadawanie prostych pytan,
- porzadkowanie cyklu zycia kontaktu,
- zmniejszenie liczby zgubionych leadow i spotkan.

## Typy uzytkownikow

Aplikacja docelowo powinna rozpoznawac typ uzytkownika i dostosowywac poziom prowadzenia.

Robocze typy:
- `Kozak` - doswiadczony agent, chce glownie szybkiego porzadkowania kontaktow.
- `Laik` - poczatkujacy agent, potrzebuje prowadzenia za reke i wielu podpowiedzi.
- `Menadzer` - osoba z duza liczba kontaktow, klientow, agentow i danych.
- `Agent terenowy` - praktyk, ktory chce prostego dzienniczka bez przeszkadzania w pracy.
- `Outsider` - osoba spoza OZE, ktora chce dopasowac aplikacje do swojego procesu.

## Onboarding i pytania aplikacji

Aplikacja powinna zadawac pytania, ktore pomoga ustalic:
- jakiego rodzaju handlowcem jest uzytkownik,
- jakie ma doswiadczenie,
- jaki ma cel zarobkowy,
- po co chce uzywac aplikacji,
- jak mocno aplikacja ma go prowadzic.

To bedzie podstawa do pozniejszego dopasowania mechaniki i komunikatow.

## Statusy robocze

Aktualne statusy moga zostac uproszczone wokol trzech etapow:
- `contact` - kontakt / lead,
- `scheduled_meeting` - umowione spotkanie,
- statusy realizacji w `clients` - etap W realizacji.

Statusy przeplywu sa czescia rdzenia aplikacji i agent nie moze ich usuwac ani edytowac:
- `contact` - Kontakt,
- `scheduled_meeting` - Umowione spotkanie,
- `signed_contract` / wynik `Sprzedane` - Spisana umowa / W realizacji.

Statusy przeplywu sluza do tego, zeby aplikacja wiedziala, w ktorej sekcji jest rekord.
Statusy robocze kontaktu sluza do opisu sytuacji kontaktu i sa edytowalne w Ustawieniach.
Domyslne statusy robocze to:
- `Do przedzwonienia`,
- `Do podjechania`,
- `Robocze`.

Domyslne statusy robocze maja od razu byc widoczne w Ustawieniach jako normalne pozycje.
Agent moze je edytowac albo usunac, tak jak wlasne statusy.

Kontakt domyslnie moze nie miec statusu roboczego.
Brak statusu kontaktu jest zapisywany jako `NULL` w `contacts.contact_status`.

Statusy kontaktow agent tworzy w Ustawieniach.
Statusy maja nazwe, kolor i ikone.
Kolor nadaje automatycznie system, a ikone agent moze wybrac z przygotowanego zestawu ikon.
W szczegolach kontaktu lista wyboru statusu pokazuje ikone obok nazwy statusu.
W kafelku kontaktu status roboczy jest pokazany jako sama ikona w prawym gornym rogu.

Typy kontaktu sa osobna warstwa od statusu i dzialaja jak tagi/karteczki.
Jeden kontakt moze miec wiele typow jednoczesnie, np. `PRO-NETWORK`, `VOTUM`, `swiadczenia zdrowotne`.
Kazdy typ ma swoj kolor ustawiany przez agenta.
W kafelku kontaktu w lewym gornym rogu pokazywane sa nazwy typow kontaktu, np. `Panele z magazynem energii, Dofinansowanie`.
Typy kontaktu zajmuja lewa, szersza czesc gornego wiersza kafelka.
Status roboczy kontaktu zajmuje prawa czesc gornego wiersza i jest pokazany jako sama ikona.
Pelne nazwy typow sa tez widoczne po wejsciu w szczegoly kontaktu.
Typy kontaktu nie sa pokazywane w sekcji Umowione spotkania.

Stare statusy pomocnicze typu:
- `quick_contact`,
- `visit_required`

nie sa aktualnym rdzeniem mechaniki.
Moga byc mapowane do `contact`, jesli pojawiaja sie w starych danych.

Nie tworzymy osobnego statusu `Ustalic termin`.
Jesli trzeba ustalic termin, kontakt wraca jako `Do przedzwonienia` z przypomnieniem.

## SMS do klienta

Mechanika SMS ma byc narzedziem szybkiej komunikacji, a nie automatycznym systemem zgadywania sytuacji agenta.
Agent nie bedzie klikal `Rozpocznij spotkanie`, wiec aplikacja nie powinna opierac SMS-ow na tym, ze wie, kiedy spotkanie faktycznie trwa.

Zasady:
- aplikacja nie wysyla SMS-a automatycznie,
- aplikacja nie pokazuje automatycznego popupu przed kolejnym spotkaniem,
- agent sam wybiera akcje `Wyslij SMS`,
- aplikacja otwiera systemowa aplikacje SMS z gotowa trescia,
- agent sam klika systemowe `Wyslij`,
- tresc mozna ewentualnie edytowac juz w systemowej aplikacji SMS.

W szczegolach umowionego spotkania ma byc akcja `Wyslij SMS`.
Po kliknieciu aplikacja pokazuje liste szablonow SMS.
Po wyborze szablonu aplikacja otwiera systemowa aplikacje SMS do numeru klienta.

Szablony SMS:
- sa konfigurowane w Ustawieniach,
- należą do sekcji `Kontakty`,
- dzialaja podobnie jak typy i statusy kontaktow,
- agent moze dodac, edytowac i usunac szablon,
- szablon ma nazwe, np. `Spoznie sie`, `Nie przyjade`, `Oddzwonie`,
- szablon ma tresc wiadomosci.

Zmienne w szablonach, np. `{imie}`, `{godzina}`, `{agent}`, zostaja odlozone na pozniej.

Podpis agenta:
- w Ustawieniach ma byc globalny przelacznik `Dopisuj podpis do SMS`,
- nie kazdy agent musi chciec podpis,
- sam tekst podpisu zostaje do doprecyzowania pozniej.

Dzwonek / nierozliczone spotkania:
- w panelu dzwonka ma byc akcja grupowa `Wyslij SMS do wszystkich`,
- grupowy SMS otwiera jedna wiadomosc SMS do wielu numerow,
- po wyslaniu SMS aplikacja powinna oznaczyc spotkania informacja typu `SMS wyslany` / `Klient poinformowany`,
- informacja o wyslanym SMS powinna byc widoczna w historii / nierozliczonych spotkaniach.

Otwarte:
- czy po grupowym SMS spotkania zostaja w nierozliczonych, czy aplikacja proponuje kolejny krok,
- czy po SMS domyslnie sugerowac telefon nastepnego dnia,
- gdzie dokladnie pokazac status `Klient poinformowany` w kafelku i historii.

## Wynik umowionego spotkania

W szczegolach umowionego spotkania agent nie wybiera juz wyniku z dlugiej listy.
Zamiast tego widzi cztery kwadraty akcji obok siebie:

1. Sprzedane - zielony kwadrat z ptaszkiem.
2. Nie sprzedane - zolty kwadrat z trojkatem ostrzegawczym.
3. Przelozone - niebieski kwadrat ze strzalka w bok.
4. Nieodbyte - spotkanie sie nie odbylo, np. klient nie odebral telefonu albo nie bylo go na miejscu.

Znaczenie:
- Sprzedane prowadzi do zapisu umowy i ewentualnego przeniesienia do W realizacji.
- Nie sprzedane uruchamia 2 kroki: powod jako pierwszy popup i wnioski na przyszlosc jako drugi popup. Potem agent wybiera, czy `Zapamietaj spotkanie`, czy `Wroc do kontaktow`.
- `Czeka na decyzje` nie jest osobnym przyciskiem, bo mogloby uczyc agenta, ze decyzji mozna biernie oczekiwac. Jest jednym z powodow w akcji `Nie sprzedane`.
- Jesli agent wybierze powod `Czeka na decyzje`, aplikacja wymaga terminu powrotu do klienta i zapisuje przypomnienie/follow-up.
- Przelozone pyta o nowy termin. Jesli termin jest znany, zostaje Umowionym spotkaniem z nowa data. Jesli terminu nie ma, wraca do Kontaktow jako `Do przedzwonienia` i trafia do przypomnien.
- Nieodbyte pyta: `Przekladamy?`.
  - Jesli tak, agent wybiera nowy termin umowionego spotkania.
  - Jesli nie, aplikacja pyta `Co robimy?` i agent wybiera: `Usun` albo `Zapamietaj spotkanie`.

Osobna sytuacja:
- Nieodbyte / klient nie odebral telefonu nie jest tym samym co Niezainteresowany.
- Niezainteresowany / beton / zla relacja powinien byc usuwany, bo nie jest wart dalszego prowadzenia.

## Zapamietaj spotkanie

`Zapamietaj spotkanie` jest akcja zapisania historii spotkania, a nie aktywnym etapem pracy.
To lepsza nazwa niz `Archiwum spotkan`, bo agent zapisuje spotkanie po to, zeby miec z niego pamiec, powod i wnioski.

Do `Zapamietanych spotkan` trafiaja przede wszystkim:
- Nie sprzedane spotkania,
- spotkania z powodami i wnioskami na przyszlosc,
- spotkania, z ktorych agent chce sie uczyc,
- spotkania, ktore nie powinny wracac do aktywnych kontaktow.

Zapamietane spotkanie powinno przechowywac:
- dane kontaktu,
- date spotkania,
- typy kontaktu,
- wynik spotkania,
- powod braku sprzedazy,
- wnioski na przyszlosc,
- notatki agenta,
- informacje, czy spotkanie wynikalo np. z `karteczki`.

`Zapamietaj spotkanie` jest czym innym niz usuniecie kontaktu.
Usuniecie dotyczy kontaktow martwych, np. Niezainteresowany / beton / zla energia.

## Archiwum cyklu

Po zakonczeniu cyklu pracy, np. nastepnego dnia, aplikacja powinna przeniesc do archiwum w Ustawieniach wszystko, co nie zostalo oznaczone wynikiem albo decyzja agenta.

Do archiwum cyklu trafiaja:
- umowione spotkania bez wyniku,
- kontakty bez dalszej decyzji,
- inne niedomkniete rekordy z zakonczonego cyklu.

Archiwum jest sekcja porzadkowa w Ustawieniach.
Nie jest glownym ekranem pracy agenta.

## Zasada projektowa

Nie projektujemy aplikacji jako zbioru przypadkowych statusow.
Projektujemy ja jako cykl zycia kontaktu, ktory ma pomagac agentowi zarabiac wiecej przez mniej zgubionych spraw.
