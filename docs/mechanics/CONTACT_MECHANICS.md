# Contact Mechanics

Ten plik jest centralnym zrodlem prawdy dla mechaniki kontaktow w wersji 1.2.
Opisuje, jak aplikacja zachowuje sie przy dodaniu kontaktu, zmianie statusu, przeprocesowaniu spotkania, pracy agenta w cyklu oraz przy podsumowaniach.
Poszczegolne sekcje aplikacji opisane w `docs/sections/` pokazuja tylko swoje fragmenty tego mechanizmu.

## Charakter mechanizmu
To jest jeden mechanizm produktowy skladajacy sie z kilku mniejszych mechanizmow:
- statusow kontaktu
- szybkich notatek
- kontaktow roboczych
- terminow do podjechania i do przedzwonienia
- umawiania spotkan
- dnia leadowania
- dnia sprzedazowego
- cyklu pracy
- licznikow i statystyk
- podsumowan

Implementacyjnie moze byc podzielony na moduly, ale produktowo powinien byc traktowany jako jeden przeplyw pracy agenta.

## Szybka notatka
Szybka notatka to sam tekst.
Nie musi miec telefonu, adresu ani danych kontaktu.
Nie jest kontaktem.
Nie liczy sie jako lead.
Nie liczy sie jako umowione spotkanie.
Nie mozna jej zamienic na kontakt.
Mozna ja tylko usunac.

## Kontakt roboczy
Kontakt roboczy to zapis sprawy, do ktorej agent ma wrocic.
Nie jest jeszcze leadem.
Nie liczy sie jako umowione spotkanie.
Musi miec przynajmniej telefon albo adres.
Sam telefon wystarczy.

Kontakt roboczy moze zostac:
- zamieniony na Umowione spotkanie
- zamieniony na Do podjechania
- wyslany do archiwum

Dopiero zamiana na Umowione spotkanie albo Do podjechania wplywa na liczniki.

## Do podjechania
Do podjechania liczy sie jako +1 lead.
Nie liczy sie jako umowione spotkanie.
Musi miec przynajmniej:
- imie albo dane kontaktu
- adres
- ogolny termin

Termin jest potrzebny, zeby aplikacja wiedziala, kiedy przypomniec agentowi, ze teraz jest czas podjechac do tego kontaktu.

Podstawowe terminy:
- za tydzien
- za miesiac
- za 3 miesiace
- wlasny termin

Gdy nadejdzie termin, aplikacja pyta agenta, co chce zrobic.
Mozliwe akcje:
- Podjezdzam
- Do archiwum / nieaktualne

## Do przedzwonienia
Do przedzwonienia tez musi miec ogolny termin.
Uzywa takich samych szybkich terminow jak Do podjechania:
- za tydzien
- za miesiac
- za 3 miesiace
- wlasny termin

Do przedzwonienia nie liczy sie jako umowione spotkanie.
O tym, czy kontakt stanie sie leadem, decyduje pozniejsza zmiana na Umowione spotkanie albo Do podjechania.

## Umowione spotkanie
Umowione spotkanie liczy sie jako +1 lead i +1 umowione spotkanie.

Minimum danych:
- imie albo dane kontaktu
- adres
- dzien spotkania
- produkt

Telefon nie jest obowiazkowy.
Adres jest obowiazkowy.
Godzina domyslna to 18:00.
Domyslny produkt to PV + ME.
Jakosc S/M/L/XL jest opcjonalna.

## Przelozone
Przelozone jest stanem przed ponownym Umowionym spotkaniem.
Nie liczy sie do aktywnego wyniku.
Ten sam kontakt nie moze zdublowac wyniku przez samo przelozenie.
Po ustawieniu nowej daty kontakt moze wrocic do Umowionego spotkania, ale nie tworzy drugiego wyniku za ten sam kontakt.

To jest delikatny obszar UX, bo agent czesto jest w pospiechu miedzy spotkaniami i nie ma czasu ustalac nowych terminow w rozbudowanym formularzu.
Aplikacja powinna prowadzic agenta krotkimi pytaniami i szybkimi akcjami.
Przelozenie nie moze wymagac dlugiej edycji kontaktu w momencie stresu.

Jesli kontakt ze stanu Przelozone zostanie ponownie zamieniony na Umowione spotkanie:
- nie dodaje ponownie +1 lead
- moze dodac +1 umowione spotkanie w nowym dniu
- nie moze zdublowac wyniku pierwotnego kontaktu w tym samym cyklu

## Odwolanie spotkania
Odwolanie jest akcja, a nie stalym statusem.
Jesli spotkanie jest odwolane i nie ma nowego terminu, kontakt jest martwy z perspektywy aktywnej pracy.
Powinien trafic poza aktywne kontakty.
Uzywamy pojecia Archiwum, nie Kosz.
Kosz oznacza trwale usuniecie i nie powinien byc glowna akcja w stresujacym przeplywie sprzedazowym.

W momencie spotkania aplikacja nie powinna wymagac od agenta dlugiego wyboru.
Jesli klient odwolal albo agent nie wszedl, aplikacja powinna prowadzic go prostym pytaniem albo jedna szybka akcja.
Docelowy efekt to:
- przeniesienie poza aktywne kontakty
- albo oznaczenie jako Przelozone, jesli agent chce wrocic do tematu

Jesli klient odwoluje przed rozpoczeciem spotkania, wplywa to na dzien sprzedazowy, ale nie cofa wyniku dnia leadowania.
Jesli agent kliknal juz Start spotkania / Wszedlem, nie traktujemy tej sytuacji jak zwyklego odwolania przed spotkaniem.

Nie wszedlem oznacza, ze agent byl pod adresem, ale nie doszlo do spotkania.
Nie liczy sie jako odbyte spotkanie.
W statystykach dnia sprzedazowego powinno byc widoczne jako spotkanie, ktore sie nie odbylo.

Przyklad podsumowania dnia sprzedazowego:
`9 umowionych, 4 odbyte, 2 przelozone, 3 nieodbyte`

## W trakcie spotkania
Etap W trakcie spotkania zaczyna sie dopiero po akcji agenta.
Przykladowa akcja:
- Start spotkania

Samo nadejscie godziny spotkania nie rozpoczyna spotkania automatycznie.
Po kliknieciu Start spotkania aplikacja pokazuje agentowi informacje typu "Spotkanie trwa..." oraz licznik czasu spotkania.
To nie powinien byc glowny status kontaktu, tylko informacja operacyjna dla agenta.
Agent moze cofnac Start spotkania, jesli kliknal przez pomylke.
Licznik spotkania ma byc widoczny caly czas na aktywnym kafelku spotkania.
Agent moze miec tylko jedno aktywne spotkanie naraz.

Start spotkania uruchamia tryb spotkania.
Tryb spotkania obejmuje:
- licznik czasu
- mikrofon
- lokalne nagrywanie spotkania
- dalsze kroki po spotkaniu

Nagrywanie powinno wlaczac sie automatycznie, poniewaz agenci moga o nim zapominac.
Agent moze w ustawieniach wybrac, czy nagrywanie ma wlaczac sie automatycznie.
Nagrania sa lokalne.
Aplikacja ma miec dostep do lokalnych nagran i analizowac je wedlug instrukcji podanej przez uzytkownika.
Nagranie jest przypiete do kontaktu/spotkania w aplikacji, ale fizycznie lezy lokalnie na telefonie.
Nagran nie wysylamy online jako glownego zrodla danych, bo nie ma na to miejsca.
Online zapisywane sa tylko konkluzje i analiza z nagran.
Te konkluzje trafiaja do agenta AI, ktory automatycznie wyciaga wnioski ze spotkania dla agenta.
Agent AI jest ukrytym mechanizmem w tle.
Nie jest osobna sekcja aplikacji.
Agent widzi efekty pracy AI przy kontakcie, statystykach, podsumowaniach albo innych miejscach kontekstowych.

Agent moze recznie usunac nagranie z poziomu aplikacji.
Usuniecie nagrania nie usuwa konkluzji ani analizy.
Konkluzja i analiza zostaja w pamieci na zawsze.

Analiza nagrania ma automatycznie tworzyc notatke albo konkluzje ze spotkania.
Powinna byc dostepna w osobnym miejscu, np. osobnej zakladce albo ustawieniach.
Dokladne miejsce wymaga dopracowania.

Analiza nagrania nie sugeruje ani nie zmienia statusu spotkania.
Zrodlem analiz i wnioskow ma byc tylko instrukcja podana agentowi AI przez uzytkownika.
Analiza dziala automatycznie i nie wymaga zatwierdzenia przez agenta przed zapisaniem.

W trakcie spotkania aplikacja moze tez prosic agenta o bardzo krotki opis, np.:
`Opisz spotkanie w 3 slowach`
Opis spotkania powinien miec przycisk Pomin.

Podczas aktywnego spotkania Dashboard powinien pokazywac jeden aktywny kafelek tego spotkania.
Agent moze wybrac szybkie opcje dla tego spotkania, np.:
- przelozone
- wszedlem / spotkanie trwa
- odwolane / nie doszlo do spotkania

## Wynik spotkania
Po zakonczeniu spotkania agent wybiera wynik:
- Spisana umowa
- Zainteresowany
- Nie zainteresowany

Flow po spotkaniu musi byc bardzo krotkie.
Akceptowalny zakres w terenie to zwykle 1-2 klikniecia.
Agenci roznie uzupelniaja wynik: niektorzy od razu po wyjsciu, niektorzy w aucie, a czesc wcale.
Aplikacja nie moze wyskakiwac z ogolnym pytaniem typu "Jak poszlo?", bo to byloby zbyt nachalne i mogloby zabic uzywalnosc.
Pytania po spotkaniu maja byc konkretne, rzeczowe i odnosic sie do przebiegu spotkania albo jego koncowki.
Tego jezyka aplikacja bedzie sie uczyc na podstawie instrukcji dla agenta AI.
Jesli agent nie chce uzupelniac od razu, ma miec akcje Pomin.

Spisana umowa dodaje +1 odbyte spotkanie i +1 umowe.
Po wyborze Spisana umowa aplikacja pokazuje popup z pytaniem, czy agent chce przeniesc kontakt do W realizacji.
Przy spisanej umowie agent powinien uzupelnic:
- produkt umowy
- kwote brutto
- opis klienta i procesu

Produkt umowy jest wybierany z listy produktow.
Agent moze sam dopisywac i zmieniac produkty w ustawieniach.
Opis klienta i procesu to praktyczna notatka dla dalszej realizacji, np.:
`Fajny pan, ale moze byc problem z odbieraniem telefonu, bo nie ma zasiegu w domu.`
Na start po spisanej umowie nie wymagamy dodatkowych obowiazkowych pol poza podstawowym wynikiem.
Kwota umowy jest znana od razu, ale czasem nie wiadomo jeszcze, ile klient wplaci.
Produkt umowy jest jeden.
Po spisanej umowie kontakt powinien przejsc do W realizacji.

Nie zainteresowany dodaje +1 odbyte spotkanie i 0 umow.
Aplikacja pyta o powod braku zainteresowania.
Podstawowe powody:
- Cena
- Musi przemyslec
- Brak osoby decyzyjnej
- Nie teraz
- Beton
- Inne

W zaleznosci od odpowiedzi aplikacja moze podpowiedziec, co zrobic dalej z kontaktem.
Przyklad: jesli powod wskazuje, ze warto wrocic do tematu za miesiac, aplikacja moze zasugerowac termin powrotu zamiast prostego zamkniecia.
Ten przeplyw wymaga osobnego dopracowania, bo jest bardzo wazny dla agenta.
Po wyborze powodu aplikacja nie zawsze musi archiwizowac kontakt.
Moze zaproponowac powrot do kontaktu po czasie, jesli powod na to wskazuje.
Powod Beton oznacza klienta definitywnie zamknietego, do ktorego nie wracamy.

Zainteresowany dodaje +1 odbyte spotkanie i 0 umow.
Po wyborze Zainteresowany aplikacja nie konczy przeplywu.
Pyta agenta: co dalej planujesz z tym kontaktem?
Agent musi wybrac dalszy krok i termin.
Kontakt moze przejsc do Do przedzwonienia albo innego dalszego kontaktu z terminem.
Opcja "Wyslij oferte" nie wchodzi teraz do tego mechanizmu.
Kontakt Zainteresowany musi miec uwagi / notatki.
Dokladny pozniejszy etap kontaktu Zainteresowany zalezy od okolicznosci i zostaje do dopracowania.
Najczestsze znaczenie Zainteresowany po spotkaniu: klient chce, ale nie teraz.
Zainteresowany moze zostac bez terminu w momencie zapisu, ale aplikacja ma po czasie przypomniec o tym kontakcie i zapytac, co robimy dalej.
Przy Zainteresowany lepiej podejsc delikatnie.
Aplikacja nie powinna od razu atakowac agenta pytaniem, co z tym spotkaniem zrobic.
Lepszy model to pozniejsza, kontekstowa sugestia:
`Pamietasz spotkanie z tym klientem? Warto byloby cos z tym zrobic. Moje zalozenia sa takie... Ja zrobilbym to i to.`
Agent moze:
- wykonac sugerowana akcje
- zamknac popup
- poprosic o inna podpowiedz
- odrzucic sugestie

Aplikacja ma dzialac jak krotki mentor / manager agenta.
Po wyniku spotkania powinna zadawac proste, szybkie pytania, ktore pomagaja agentowi podjac nastepny krok bez dlugiego formularza.
Spotkania nie mozna zakonczyc bez wyboru wyniku.
Zawsze musi zostac wybrany jakis wynik, nawet jesli jest to Nie zainteresowany.

Wszedlem / Start spotkania samo w sobie nic nie liczy.
Dopiero zakonczenie spotkania wynikiem dodaje statystyke odbycia.

## Przelozenie w dniu sprzedazowym
Gdy agent wybiera Przelozone, aplikacja pyta:
`Masz nowy termin?`

Odpowiedzi:
- Tak
- Nie teraz

Jesli agent wybierze Tak, aplikacja pozwala szybko ustawic nowy termin.
Jesli agent wybierze Nie teraz, kontakt zostaje w stanie Przelozone.
Aplikacja powinna przypomniec agentowi o ustaleniu nowego terminu zanim zamknie cykl.
Docelowo aplikacja powinna wymagac, zeby agent zapytal klienta o nowy termin od razu.
Jesli nowego terminu nie ma, aplikacja przypomina przed zamknieciem cyklu:
`Tu masz jeszcze niedomkniete spotkanie. Zrob cos z tym.`

## Status spotkania w dniu sprzedazowym
Zamiast ciezkiego statusu typu "Nie wszedlem" aplikacja powinna pytac agenta roboczo o status spotkania.
Jezyk ma byc prosty i operacyjny, np.:
- Co stalo sie ze spotkaniem?
- Czy spotkanie sie odbylo?
- Jaki jest wynik tej wizyty?

Dokladne etykiety przyciskow wymagaja osobnego dopracowania.
Nie powinny brzmiec technicznie ani oskarzajaco.
Na start przy spotkaniu, ktore sie nie odbylo, nie pytamy o powod.
Powodow jest zbyt wiele i taki formularz bylby zbyt ciezki.
Wystarczy szybka akcja.

Jesli spotkanie sie nie odbylo, aplikacja pokazuje dwa glowne przyciski:
- Archiwizuj
- Przeloz spotkanie

Po wyborze Przeloz spotkanie aplikacja pyta, czy agent zna termin.
Jesli zna termin, ustawia go od razu.
Jesli nie zna terminu, ustawia przypomnienie pozniej.

## Powody po wyniku Nie zainteresowany
Po Nie zainteresowany aplikacja pyta o powod.
Domyslnie kontakt idzie do archiwum, chyba ze powod sugeruje powrot.
Jesli agent ma niepewnosc, aplikacja powinna pomoc mu podjac decyzje.

Powody, ktore moga oznaczac powrot pozniej:
- Musi przemyslec
- Nie teraz
- Brak osoby decyzyjnej
- Inne, jesli tresc nawiazuje do "nie teraz"

Powody, ktore zwykle zamykaja temat:
- Cena
- Beton
- Inne, jesli tresc nawiazuje do definitywnego "nie"

Agent moze dopisac wlasny powod jako dodatkowa informacje.
Na start wlasny powod nie jest kluczowym elementem logiki aplikacji.
Jesli z czasem pojawi sie wiele podobnych powodow, mozna z nich zbudowac nowe reguly.

## Styl mentora
Aplikacja ma mowic bardziej managersko niz neutralnie.
Nie chodzi tylko o przyciski, ale o sugestie i prowadzenie agenta.
Jezyk oraz sposob mowy beda ustalane przez instrukcje agenta AI.
Komunikaty moga byc krotkie i konkretne, ale czasem tez motywacyjne.

Sugestie powinny miec charakter inspirujacy i pewny siebie, np.:
`Ten kontakt warto odzyskac za 30 dni. Ja bym zrobil to tak...`

Agent ma czuc, ze aplikacja jest mocnym partnerem i podpowiada, co sama zrobilaby na jego miejscu.

## Liczniki leadowania
Aktywny kafelek leadowania pokazuje liczniki obok siebie:
`Umowione: 4/9 | Leady: 6 | Czas: 01:12:33`

Reguly:
- Umowione spotkanie = +1 lead i +1 umowione.
- Do podjechania = +1 lead i 0 umowionych.
- Kontakt roboczy = 0 leadow i 0 umowionych.
- Szybka notatka = 0 leadow i 0 umowionych.

Jesli agent doda spotkanie bez klikniecia Start, aplikacja tylko zapisuje kontakt.
Nie rozpoczyna automatycznie sesji ani cyklu.

## Liczniki dnia sprzedazowego
Reguly:
- Start spotkania = 0 odbyte i 0 umow.
- Spisana umowa = +1 odbyte i +1 umowa.
- Nie zainteresowany = +1 odbyte i 0 umow.
- Zainteresowany = +1 odbyte i 0 umow.
- Nie wszedlem / nie doszlo do spotkania = 0 odbyte i 0 umow.
- Przelozone = 0 odbyte i 0 umow w biezacym dniu.

Dzien sprzedazowy powinien umiec pokazac rozklad spotkan, np.:
`9 umowionych | 4 odbyte | 2 przelozone | 3 nieodbyte`

## Kolejnosc spotkan w dniu sprzedazowym
Aplikacja nie powinna automatycznie zakladac, na ktorym spotkaniu agent aktualnie jest.
Agent moze recznie rozpoczac dowolne spotkanie z listy.
Aktywny kafelek dnia sprzedazowego pokazuje spotkanie, ktore agent aktualnie wybral/rozpoczal.

Jesli minie godzina spotkania i agent nic nie kliknie, kontakt trafia do Zalegle / Wymaga akcji.
Zalegle spotkanie moze pozniej zostac oznaczone jako:
- odbyte
- nie wszedlem / nie doszlo do spotkania
- przelozone
- archiwum

## Historia dzialan
Historia powinna zapisywac:
- kiedy agent kliknal Start spotkania
- cofniecie Start spotkania, jesli bylo klikniete przez pomylke
- czas trwania spotkania
- wynik spotkania
- przelozenie
- odwolanie
- nieodbyte spotkanie / nie wszedlem

## Dzien i typ pracy
Aplikacja ma probowac sama rozpoznac typ dnia:
- leadowanie
- dzien sprzedazowy
- dzien wolny / organizacyjny

Aplikacja moze tez zapytac agenta o potwierdzenie.
W dzien wolny aplikacja pokazuje spokojny stan, a nie pusta przestrzen.

## Cykl pracy
Cykl pracy laczy dzien leadowania i dzien sprzedazowy.
Dzien leadowania generuje spotkania i leady.
Dzien sprzedazowy rozlicza, czy spotkania sie odbyly.

Cykl konczy agent przyciskiem Zakoncz cykl.
Jesli agent tego nie zrobi, cykl zamyka sie automatycznie po koncu dnia, czyli po 00:00:00 kolejnego dnia.

## Podsumowania
Po leadowaniu aplikacja pokazuje podsumowanie dnia leadowania.
Po sprzedazy aplikacja pokazuje podsumowanie dnia sprzedazowego.
Potem pokazuje Podsumowanie cyklu z gratulacjami.

Porownanie cyklu do poprzedniego cyklu obejmuje:
- Umowione spotkania
- Odbyte spotkania
- Liczbe leadow

Porownanie tygodnia albo dluzszego okresu obejmuje:
- Umowione spotkania
- Odbyte spotkania
- Liczbe leadow
- Spisane umowy

Przerwa nie jest glowna metryka podsumowania.

## Cel mechanizmu
Mechanizm ma dawac porzadek pracy i statystyke.
Nie ma sztywno wymuszac modelu 9 umowionych -> 4 odbyte -> 1 umowa.

# Flow uzytkownika

Ta sekcja opisuje, co agent widzi i robi krok po kroku.
Sekcje powyzej opisuja zasady.
Flow ponizej opisuje praktyczne zachowanie aplikacji.

## Flow: Dzien leadowania

Cel:
Agent zaczyna prace w terenie i widzi wynik dnia w jednym miejscu.

Kroki:
1. Aplikacja rozpoznaje albo pyta, czy dzis jest dzien leadowania.
2. Dashboard pokazuje aktywny kafelek leadowania.
3. Agent ustala cel, np. 9 umowionych spotkan.
4. Agent klika Start.
5. Aplikacja uruchamia licznik czasu.
6. Kafelek pokazuje: `Umowione: 0/9 | Leady: 0 | Czas: 00:00:00`.
7. Agent korzysta z szybkich akcji pod kafelkiem.

Szybkie akcje:
- Umow spotkanie
- Do podjechania
- Do przedzwonienia
- Kontakt roboczy
- Szybka notatka
- Przerwa
- Koniec

Wynik:
Agent ma stale widoczny wynik i czas pracy.

## Flow: Dodanie umowionego spotkania

Cel:
Agent szybko zapisuje spotkanie, ktore ma odbyc sie w przyszlosci.

Kroki:
1. Agent klika Umow spotkanie.
2. Aplikacja otwiera formularz spotkania.
3. Agent wpisuje dane kontaktu.
4. Agent musi wpisac adres.
5. Aplikacja ustawia domyslna godzine 18:00.
6. Aplikacja ustawia domyslny produkt PV + ME.
7. Agent zapisuje kontakt.

Wynik:
Kontakt ma status Umowione spotkanie.
Dodaje +1 lead i +1 umowione.

## Flow: Dodanie Do podjechania

Cel:
Agent zapisuje kontakt, do ktorego trzeba podjechac w przyszlosci.

Kroki:
1. Agent klika Do podjechania.
2. Aplikacja wymaga danych kontaktu i adresu.
3. Agent wybiera ogolny termin.
4. Dostepne szybkie terminy: za tydzien, za miesiac, za 3 miesiace, wlasny termin.
5. Agent zapisuje kontakt.

Wynik:
Kontakt liczy sie jako +1 lead i 0 umowionych.
Aplikacja wie, kiedy przypomniec o podjechaniu.

## Flow: Przypomnienie Do podjechania

Cel:
Aplikacja przypomina agentowi, ze nadszedl czas na podjechanie.

Kroki:
1. Nadszedl termin Do podjechania.
2. Aplikacja pokazuje przypomnienie.
3. Agent widzi pytanie w stylu: teraz jest czas podjechac do tego kontaktu, co robimy?
4. Agent wybiera Podjezdzam albo Do archiwum / nieaktualne.

Wynik:
Kontakt wraca do aktywnej pracy albo zostaje zamkniety w archiwum.

## Flow: Dodanie Do przedzwonienia

Cel:
Agent zapisuje kontakt, do ktorego ma zadzwonic pozniej.

Kroki:
1. Agent klika Do przedzwonienia.
2. Aplikacja wymaga danych potrzebnych do kontaktu.
3. Agent wybiera ogolny termin.
4. Dostepne szybkie terminy: za tydzien, za miesiac, za 3 miesiace, wlasny termin.
5. Agent zapisuje kontakt.

Wynik:
Aplikacja wie, kiedy przypomniec agentowi o telefonie.

## Flow: Kontakt roboczy

Cel:
Agent zapisuje kontakt, ktory nie jest jeszcze leadem.

Kroki:
1. Agent klika Kontakt roboczy.
2. Aplikacja wymaga telefonu albo adresu.
3. Agent zapisuje kontakt.

Mozliwe dalsze akcje:
- zamien na Umowione spotkanie
- zamien na Do podjechania
- archiwizuj

Wynik:
Kontakt roboczy nie liczy sie do leadow ani umowionych spotkan.
Dopiero zamiana na inny typ wplywa na liczniki.

## Flow: Szybka notatka

Cel:
Agent zapisuje luzna mysl albo informacja tekstowa bez tworzenia kontaktu.

Kroki:
1. Agent klika Szybka notatka.
2. Wpisuje dowolny tekst.
3. Zapisuje notatke.

Mozliwe dalsze akcje:
- usun

Wynik:
Szybka notatka nic nie liczy i nie moze byc zamieniona na kontakt.

## Flow: Dzien sprzedazowy

Cel:
Agent rozlicza spotkania zaplanowane na dany dzien.

Kroki:
1. Aplikacja rozpoznaje albo pyta, czy dzis jest dzien sprzedazowy.
2. Dashboard pokazuje spotkania na dzis.
3. Agent wybiera spotkanie, na ktorym aktualnie jest.
4. Aplikacja pokazuje aktywny kafelek wybranego spotkania.

Wynik:
Aplikacja nie zaklada automatycznie, na ktorym spotkaniu jest agent.
Agent sam rozpoczyna wybrane spotkanie.

## Flow: Start spotkania

Cel:
Agent uruchamia tryb spotkania.

Kroki:
1. Agent wybiera spotkanie.
2. Klika Start spotkania.
3. Aplikacja uruchamia licznik czasu.
4. Jesli ustawienie jest wlaczone, aplikacja automatycznie uruchamia lokalne nagrywanie.
5. Aplikacja pokazuje aktywny kafelek: Spotkanie trwa...
6. Licznik spotkania jest widoczny caly czas.

Opcjonalnie:
- agent moze pominac krotki opis spotkania
- agent moze cofnac Start spotkania, jesli kliknal przez pomylke

Wynik:
Spotkanie jest aktywne, ale jeszcze nic nie liczy sie do statystyk.

## Flow: Zakoncz spotkanie

Cel:
Agent konczy aktywne spotkanie i wybiera wynik.

Kroki:
1. Agent klika Zakoncz spotkanie.
2. Aplikacja zatrzymuje licznik.
3. Aplikacja konczy nagrywanie lokalne.
4. Agent musi wybrac wynik.

Wyniki:
- Spisana umowa
- Zainteresowany
- Nie zainteresowany

Wynik:
Spotkania nie mozna zakonczyc bez wyboru wyniku.

## Flow: Spisana umowa

Cel:
Agent zapisuje, ze spotkanie zakonczylo sie umowa.

Kroki:
1. Agent wybiera Spisana umowa.
2. Aplikacja zapisuje +1 odbyte i +1 umowa.
3. Aplikacja pyta, czy przeniesc kontakt do W realizacji.
4. Agent uzupelnia albo potwierdza podstawowe dane umowy.

Dane:
- produkt umowy
- kwota brutto
- opis klienta i procesu

Wynik:
Kontakt przechodzi do W realizacji.

## Flow: Zainteresowany

Cel:
Agent zapisuje, ze klient chce, ale nie teraz.

Kroki:
1. Agent wybiera Zainteresowany.
2. Aplikacja zapisuje +1 odbyte i 0 umow.
3. Agent dodaje uwagi / notatki, jesli sa potrzebne.
4. Aplikacja nie atakuje od razu dlugim formularzem.
5. Po czasie aplikacja wraca z kontekstowa sugestia.

Przyklad pozniejszej sugestii:
`Pamietasz spotkanie z tym klientem? Warto byloby cos z tym zrobic. Ja zrobilbym to tak...`

Mozliwe reakcje agenta:
- wykonaj sugerowana akcje
- zamknij popup
- popros o inna podpowiedz
- odrzuc sugestie

Wynik:
Kontakt zostaje do dalszej pracy, ale bez nachalnego flow od razu po spotkaniu.

## Flow: Nie zainteresowany

Cel:
Agent zapisuje odmowe i powod.

Kroki:
1. Agent wybiera Nie zainteresowany.
2. Aplikacja zapisuje +1 odbyte i 0 umow.
3. Aplikacja pyta o powod.

Powody:
- Cena
- Musi przemyslec
- Brak osoby decyzyjnej
- Nie teraz
- Beton
- Inne

Wynik:
Kontakt trafia do archiwum albo aplikacja proponuje powrot pozniej, jesli powod na to wskazuje.

## Flow: Spotkanie sie nie odbylo

Cel:
Agent szybko zamyka albo przesuwa spotkanie, ktore nie doszlo do skutku.

Kroki:
1. Agent wybiera szybka akcje dla spotkania, ktore sie nie odbylo.
2. Aplikacja nie pyta o powod.
3. Aplikacja pokazuje dwa przyciski: Archiwizuj i Przeloz spotkanie.

Jesli agent wybiera Archiwizuj:
1. Kontakt trafia poza aktywne kontakty.
2. Spotkanie liczy sie jako nieodbyte.

Jesli agent wybiera Przeloz spotkanie:
1. Aplikacja pyta: Masz nowy termin?
2. Jesli Tak, agent ustawia termin.
3. Jesli Nie teraz, aplikacja ustawia przypomnienie przed zamknieciem cyklu.

Wynik:
Spotkanie nie dodaje odbycia ani umowy.

## Flow: Przelozone

Cel:
Agent przesuwa spotkanie bez dublowania wyniku.

Kroki:
1. Agent wybiera Przelozone.
2. Aplikacja pyta: Masz nowy termin?
3. Jesli Tak, agent wybiera nowa date.
4. Jesli Nie teraz, kontakt zostaje niedomkniety.
5. Aplikacja przypomina przed zamknieciem cyklu.

Wynik:
Przelozone nie liczy sie do aktywnego wyniku.
Ponowne umowienie nie dodaje drugi raz leada.

## Flow: Zalegle spotkanie

Cel:
Agent rozlicza spotkanie, ktore minelo bez akcji.

Kroki:
1. Mija godzina spotkania.
2. Agent nie kliknal zadnej akcji.
3. Aplikacja oznacza spotkanie jako Zalegle / Wymaga akcji.
4. Agent moze pozniej wybrac wynik.

Mozliwe akcje:
- odbyte
- nie odbylo sie
- przelozone
- archiwum

Wynik:
Spotkanie nie znika i wymaga domkniecia.

## Flow: Zakonczenie dnia leadowania

Cel:
Agent konczy prace terenowa i widzi wynik dnia.

Kroki:
1. Agent klika Koniec.
2. Aplikacja zatrzymuje licznik leadowania.
3. Aplikacja pokazuje podsumowanie dnia leadowania.

Metryki:
- umowione spotkania
- leady
- czas leadowania
- realizacja celu

Wynik:
Dane zapisuja sie do statystyk.

## Flow: Zakonczenie dnia sprzedazowego

Cel:
Agent domyka spotkania i przygotowuje podsumowanie cyklu.

Kroki:
1. Agent klika Zakoncz dzien sprzedazowy albo Zakoncz cykl.
2. Aplikacja sprawdza niedomkniete spotkania.
3. Jesli sa przelozone bez terminu, aplikacja przypomina o nich.
4. Agent domyka albo pomija zalegle decyzje zgodnie z flow.
5. Aplikacja pokazuje podsumowanie dnia sprzedazowego.
6. Aplikacja pokazuje podsumowanie cyklu z gratulacjami.

Metryki dnia sprzedazowego:
- umowione
- odbyte
- przelozone
- nieodbyte
- spisane umowy

Porownanie cyklu:
- umowione spotkania
- odbyte spotkania
- leady

Wynik:
Cykl zostaje zamkniety.
