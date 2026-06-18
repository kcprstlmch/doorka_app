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
- wyniki tygodnia.

## Aktywny kafelek
Aktywny kafelek pokazuje dzien umawiania spotkan.
Po kliknieciu Start uruchamia licznik czasu.

Kafelek pokazuje:
`Obecny cel: X/Y | Kontakty: Z | 00:00:00`

`X` to liczba umowionych spotkan wynikajaca z faktycznych rekordow spotkan na dany dzien.
Nie zalezy od tego, ile razy agent kliknal Start.

## Akcje w aktywnym kafelku
Po uproszczeniu zostaja tylko dwie glowne akcje:
- Umow spotkanie
- Dodaj kontakt

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

## Nieprzerobione spotkania
Spotkania niedomkniete nie powinny przepychac glownego dashboardu.
Sa dostepne w Ustawieniach jako lista Nieprzerobione spotkania.

Na tej liscie sa:
- przeszle umowione spotkania bez wyniku,
- spotkania aktywne bez domkniecia,
- spotkania przelozone bez powrotu do normalnego terminu.

Dashboard pokazuje aktualna prace, a Ustawienia przechowuja liste do posprzatania.

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
