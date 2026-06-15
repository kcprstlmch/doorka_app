# Procesy użytkownika

Ten plik opisuje najważniejsze procesy pracy agenta w aplikacji.

## Założenia
Na teraz nie opisujemy osobno dnia leadowego i dnia sprzedażowego jako osobnych procesów, ponieważ ich finalny kształt nie jest jeszcze przesądzony.
Proces dodawania kontaktu będzie najprawdopodobniej dostępny głównie przez Przycisk Szybkiej Akcji.
Istniejąca aplikacja webowa w `/Users/kacstelmach/crm` jest używana jako techniczna referencja dla działających procesów, ale nowe procesy Fluttera muszą być zgodne z aktualną dokumentacją.

## Sekcje aplikacji
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

## Archiwizacja kontaktu
Agent może przenieść kontakt do archiwum.
Przed archiwizacją aplikacja pokazuje popup z pytaniem, czy agent na pewno chce przenieść kontakt do archiwum.
Po potwierdzeniu kontakt znika z aktywnej listy kontaktów i trafia do archiwum.

## Usuwanie permanentne z archiwum
Agent może usuwać dane permanentnie z archiwum.
Przed trwałym usunięciem aplikacja pokazuje ostrzeżenie, że danych nie będzie można przywrócić.
Agent może zaznaczyć, które kontakty chce usunąć permanentnie, a które zostawić w archiwum.

## Archiwum klientów
Archiwum klientów działa podobnie jak archiwum kontaktów.
Trwałe usunięcie klienta wymaga potwierdzenia i komunikatu, że danych nie będzie można przywrócić.
Trwałe usuwanie jest możliwe tylko z archiwum.
Potwierdzenie trwałego usunięcia odbywa się przez popup, bez wpisywania słowa USUŃ.

## Usunięcie konta
Agent może sam usunąć konto po potwierdzeniu przez e-mail.
Z perspektywy aplikacji konto znika od razu.
Technicznie konto może mieć 30 dni karencji w bazie danych, ale agent nie powinien widzieć tej informacji w aplikacji.

## Reset hasła
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło.
Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.
Reset hasła nie dotyczy użytkowników logujących się przez Google.

## Przypomnienia
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Agent może wybrać Przypomnij później za 15 minut, maksymalnie.
