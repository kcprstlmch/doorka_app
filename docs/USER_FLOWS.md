# Procesy użytkownika

Ten plik opisuje najważniejsze procesy pracy agenta w aplikacji.

## Założenia
Na teraz nie opisujemy osobno dnia leadowego i dnia sprzedażowego jako osobnych procesów, ponieważ ich finalny kształt nie jest jeszcze przesądzony.
Proces dodawania kontaktu będzie najprawdopodobniej dostępny głównie przez Przycisk Szybkiej Akcji.
Istniejąca aplikacja webowa w `/Users/kacstelmach/crm` jest używana jako techniczna referencja dla działających procesów, ale nowe procesy Fluttera muszą być zgodne z aktualną dokumentacją.

## Sekcje aplikacji
Aktualny glowny przeplyw aplikacji opiera sie na trzech pierwszych sekcjach:
- Kontakty / Zebrane leady
- Umowione spotkania
- W realizacji

Rekord moze przechodzic:
- z `Kontakty` do `Umowione spotkania`,
- z `Umowione spotkania` do `Kontakty`,
- z `Umowione spotkania` do `W realizacji`,
- z `W realizacji` do `Umowione spotkania`.

Nie przechodzimy bezposrednio z `Kontakty` do `W realizacji`.
Nie przechodzimy bezposrednio z `W realizacji` do `Kontakty`.

Szczegółowe procesy dla głównych sekcji znajdują się w:
- Dashboard: `docs/sections/Dashboard.md`
- Kontakty: `docs/sections/Contacts.md`
- W realizacji: `docs/sections/In_process.md`
- Statystyka: `docs/sections/Statistics.md`
- Ustawienia: `docs/sections/Settings.md`

## Dzwonienie
Kliknięcie numeru telefonu ma korzystać z funkcji dzwonienia w telefonie.
Aplikacja nie pokazuje po zakończeniu połączenia pytania o zmianę statusu ani notatkę.

## Mapy
Przy adresie klienta albo kontaktu aplikacja ma mieć przycisk otwarcia zewnętrznej mapy.
Agent może dzięki temu uruchomić nawigację bez ręcznego wpisywania adresu.

## Usuwanie kontaktu
Agent może usunąć kontakt z listy.
Przed usunięciem aplikacja pokazuje popup z pytaniem, czy agent na pewno chce wykonać tę akcję.
Po potwierdzeniu kontakt znika z aktywnej listy kontaktów.


## Usunięcie konta
Agent może sam usunąć konto po potwierdzeniu przez e-mail.
Z perspektywy aplikacji konto znika od razu.
Technicznie konto może mieć 30 dni karencji w bazie danych, ale agent nie powinien widzieć tej informacji w aplikacji.

## Reset hasła
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło.
Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.

## Rejestracja
Agent może samodzielnie utworzyć konto w aplikacji.
Na teraz do rejestracji konta wymagane są tylko e-mail i hasło.
Nie wymagamy imienia, nazwiska, telefonu ani innych danych profilu na etapie rejestracji.
Po założeniu konta aplikacja pokazuje informację, że na adres e-mail został wysłany link aktywacyjny.
Agent kończy rejestrację przez wejście w link aktywacyjny z wiadomości e-mail.

## Przypomnienia
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Agent może wybrać Przypomnij później za 15 minut, maksymalnie.
