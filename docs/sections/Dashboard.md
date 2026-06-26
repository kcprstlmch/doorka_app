# Dashboard

Ten plik jest zrodlem prawdy dla sekcji Dashboard.
Opisuje aktualny ekran glowny i uproszczona mechanike dnia umawiania spotkan.

## Rola sekcji
Dashboard jest glownym ekranem pracy agenta.
Ma szybko pokazac:
- aktywny dzien umawiania spotkan,
- obecny cel,
- umowione spotkania,
- zebrane kontakty,
- przypomnienia i powiadomienia,
- wyniki tygodnia.

## Aktywny kafelek
Aktywny kafelek pokazuje dzien umawiania spotkan.
Po kliknieciu Start uruchamia licznik czasu.
Licznik czasu pracy dziala takze po schowaniu aplikacji.

Przycisk `Przerwa` zatrzymuje licznik czasu pracy i zaczyna liczyc czas przerwy.
Po ponownym kliknieciu przycisk zmienia sie w `Wznow` i licznik czasu pracy rusza dalej.
Czas przerwy jest zapisywany osobno jako `break_seconds`.

Przycisk `Koniec leadowania` konczy aktywna sesje.
Po zakonczeniu aplikacja zapisuje czas pracy jako `work_seconds` i laczny czas przerwy jako `break_seconds`.

Kafelek pokazuje:
`Obecny cel: X/Y | Kontakty: Z | 00:00:00`

`X` to liczba umowionych spotkan wynikajaca z faktycznych rekordow spotkan na dany dzien.
Nie zalezy od tego, ile razy agent kliknal Start.

## Akcje w aktywnym kafelku
Po uproszczeniu zostaja glowne akcje:
- Umow spotkanie
- Dodaj kontakt
- Przerwa / Wznow
- Koniec leadowania

Nie ma juz szybkich akcji:
- Kontakt roboczy
- Do podjechania
- Do przedzwonienia
- Szybka notatka

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
