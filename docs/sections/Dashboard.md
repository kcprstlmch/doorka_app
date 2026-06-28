# Dashboard

Ten plik jest zrodlem prawdy dla sekcji Dashboard.
Opisuje aktualny ekran glowny i uproszczona mechanike dnia umawiania spotkan.

## Rola sekcji
Dashboard jest glownym ekranem pracy agenta.
Ma szybko pokazac:
- szybkie akcje pracy agenta,
- zebrane kontakty,
- przypomnienia i powiadomienia,
- wyniki tygodnia.

## Szybkie akcje na gorze
Dashboard nie ma juz aktywnego kafelka dnia, przycisku Start ani licznika czasu leadowania.
Pierwszym elementem na gorze Dashboardu jest kafelek szybkich akcji.

Glowne akcje:
- Umow spotkanie
- Dodaj kontakt
- Kontakt roboczy
- Dodaj wlasne

Akcje sa zawsze widoczne, bez rozpoczynania sesji.
Klikniecie `Umow spotkanie` otwiera formularz dodawania kontaktu jako umowione spotkanie.
Klikniecie `Dodaj kontakt` otwiera formularz zwyklego kontaktu.
Klikniecie `Kontakt roboczy` tworzy kontakt roboczy zgodnie z zasada: brak typu i brak statusu oznacza kontakt roboczy.
Klikniecie `Dodaj wlasne` prowadzi do konfiguracji wlasnych statusow/ustawien kontaktow.

## Umowione spotkania
Sekcja Umowione spotkania pokazuje rekordy ze statusem `scheduled_meeting`.
Spotkania sa filtrowane po dacie spotkania.

Pojedynczy kafelek spotkania pokazuje:
- godzine,
- dane kontaktu,
- ikone nawigacji do adresu,
- ikone telefonu,
- notatke pod spodem, jesli istnieje.

Godzina spotkania moze byc edytowana przez klikniecie godziny.

## Powiadomienia
Na gorze po prawej stronie, obok przycisku Konto, powinna byc ikona powiadomien.
Po kliknieciu wysuwa sie z gory lista powiadomien.

Powiadomienia sluza do przypomnien wynikajacych z cyklu zycia kontaktu:
- Nie sprzedane z powodem `Czeka na decyzje` - przypomnienie o telefonie po ustalonym czasie,
- Przelozone bez terminu - przypomnienie o ustaleniu nowego terminu,
- Nieodbyte / nie odebral telefonu - pytanie `Przekladamy?`, a jesli nie, wybor `Usun` albo `Zapamietaj spotkanie`,
- Kontakt ze statusem Do przedzwonienia albo Do podjechania - przypomnienie zgodne z terminem agenta.

W panelu powiadomien / nierozliczonych spotkan ma byc dostepna akcja grupowa `Wyslij SMS do wszystkich`.
Nie wysyla ona SMS automatycznie.
Otwiera systemowa aplikacje SMS z wieloma odbiorcami i gotowa trescia z wybranego szablonu.
Agent finalnie sam klika `Wyslij`.

Po uzyciu SMS aplikacja powinna zapisac przy spotkaniu informacje `SMS wyslany` albo `Klient poinformowany`.
Ta informacja powinna byc pozniej widoczna w historii / nierozliczonych spotkaniach.

Nie pokazujemy automatycznych popupow SMS przed kolejnym spotkaniem.
Praca terenowa jest zbyt dynamiczna i aplikacja nie powinna zgadywac, czy agent faktycznie jest na spotkaniu.

## Archiwum cyklu
Spotkania i kontakty niedomkniete w zakonczonym cyklu nie powinny przepychac glownego dashboardu.
Po zakonczeniu cyklu, np. nastepnego dnia, powinny trafic do Archiwum w Ustawieniach.

Do archiwum cyklu trafiaja:
- umowione spotkania bez wybranego wyniku,
- kontakty bez dalszej decyzji,
- inne rekordy, ktorych agent nie oznaczyl w trakcie cyklu.

Dashboard pokazuje aktualna prace.
Archiwum jest miejscem porzadkowym i nalezy do Ustawien.

## Zebrane kontakty
Sekcja zebranych kontaktow pokazuje zwykle kontakty ze statusem `contact`.
Nie pokazuje umowionych spotkan.

Kontakt moze zostac usuniety gestem przesuniecia w lewo.

## Liczniki
Umowione spotkanie liczy sie jako umowione spotkanie wedlug daty zapisanej w rekordzie.
Kontakt jest liczony osobno.
Kontakt nie dubluje wyniku spotkania.

## W tym tygodniu
Kafelek W tym tygodniu pokazuje podsumowanie wynikow i porownania.
Jego dane powinny wynikac z kontaktow, spotkan i spraw W realizacji, a nie z recznego dopisywania.

Aktualny kafelek statystyk pokazuje automatycznie:
- Spisane umowy,
- Odbyte spotkania,
- Umowione spotkania.

Tydzien liczony jest od poniedzialku 00:00 do kolejnego poniedzialku 00:00.

`Umowione spotkania` w statystyce tygodniowej oznaczaja spotkania przypadajace na dany tydzien, czyli liczone po `contact_date`.
Jesli rekord ma date spotkania i godzine, aplikacja traktuje go jako umowione spotkanie nawet wtedy, gdy agent nie kliknal dodatkowej akcji przy spotkaniu.
Przyklad: jesli agent we wtorek ma 7 spotkan, a w czwartek ma 11 spotkan, to tygodniowo powinno pokazac 18 umowionych spotkan.

Wynik konkretnego dnia leadowania to osobna metryka i moze liczyc spotkania po dacie ich dodania/umowienia.

`Odbyte spotkania` wynikaja ze statusu/wyniku spotkania albo z tego, ze zaplanowana godzina spotkania juz minela.
To zabezpiecza sytuacje terenowa, w ktorej agent byl na spotkaniu, ale nie kliknal nic w aplikacji.
`Spisane umowy` wynikaja z daty podpisania umowy.
