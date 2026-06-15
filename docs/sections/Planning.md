# Planowanie pracy

Ten plik opisuje pomysl na sekcje planowania miesiaca, tygodnia i dnia.
Na tym etapie temat jest odlozony.
Najwazniejsza potrzeba nie dotyczy teraz rozbudowanego planowania miesiaca, tylko codziennej realizacji celu na Dashboardzie.
Szczegoly tej potrzeby sa opisane w `docs/sections/Dashboard.md`.

## Rola sekcji

Planowanie pracy ma pomagac agentowi zaplanowac wynik przed rozpoczeciem pracy.
Nie chodzi tylko o zwykly kalendarz.
Chodzi o narzedzie, w ktorym agent moze rozpisac plan:

- ile spotkan chce umowic
- ile spotkan chce odbyc
- jak wyglada plan dnia
- jak wyglada plan tygodnia
- jak wyglada plan miesiaca

Sekcja moze byc uzywana takze w relacji agent-manager.
Przyklad: menadzer prosi agenta, zeby zaplanowal miesiac, a agent uklada plan w aplikacji i wysyla zrzut ekranu.

## Status

Temat planowania pracy zostaje na pozniejszy etap.
Nie projektujemy teraz osobnej sekcji planowania.
W pierwszej kolejnosci aplikacja ma pomagac agentowi realizowac dzienny cel i korygowac wynik dnia w Dashboardzie.

## Widoki

Docelowo sekcja moze miec trzy poziomy:

- miesiac
- tydzien
- dzien

## Widok miesiaca

Widok miesiaca powinien pokazywac dni w formie kalendarza.
Agent moze wpisywac liczby przy konkretnych dniach.

Przykladowe dane do wpisania:

- planowana liczba umowionych spotkan
- planowana liczba odbytych spotkan
- ewentualnie planowana liczba umow do podpisania

Widok miesiaca moze sluzyc do wyslania menadzerowi jako zrzut ekranu.
Dlatego powinien byc czytelny, estetyczny i latwy do pokazania poza aplikacja.

## Widok tygodnia

Widok tygodnia powinien pokazac plan na poszczegolne dni tygodnia.
Moze byc bardziej szczegolowy niz miesiac.

Przykladowe dane:

- ile spotkan agent chce umowic danego dnia
- ile spotkan agent chce odbyc danego dnia
- ktore dni sa leadowaniem
- ktore dni sa sprzedaza
- ktore dni sa organizacyjne albo wolne

## Widok dnia

Widok dnia powinien pomagac agentowi zaplanowac konkretna prace.
Moze pokazywac:

- cel dnia
- planowana liczbe spotkan
- planowana liczbe kontaktow
- czas w terenie
- notatke planistyczna

## Dane planowane a dane wykonane

Docelowo aplikacja powinna moc porownac plan z wykonaniem.

Przyklad:

- plan: 9 umowionych spotkan
- wykonanie: 7 umowionych spotkan
- roznica: -2

To moze byc pozniej powiazane z Dashboardem i Statystyka.

## Relacja z Dashboardem

Dashboard pokazuje aktualny wynik i biezaca prace.
Planowanie pokazuje zalozenia przed praca.

Te sekcje powinny sie uzupelniac:

- Planowanie: co agent zaklada
- Dashboard: co dzieje sie dzisiaj i w tym tygodniu
- Statystyka: co faktycznie zostalo wykonane

## Relacja z ustawieniami

W ustawieniach moze pojawic sie domyslny sposob planowania:

- domyslny widok: miesiac, tydzien albo dzien
- domyslne cele
- dni leadowania
- dni sprzedazowe

## Pytania do doprecyzowania

- Czy planowanie ma byc osobna sekcja w dolnej nawigacji, czy czescia Dashboardu albo Statystyki?
- Czy agent ma wpisywac tylko liczby, czy takze notatki?
- Czy plan miesiaca ma miec przycisk eksportu / udostepnienia, czy wystarczy zrzut ekranu telefonu?
- Czy manager docelowo ma widziec plan agenta w aplikacji, czy na razie tylko przez screen?
- Czy planowanie dotyczy tylko spotkan, czy tez czasu w terenie i liczby kontaktow?
