# Ustawienia

Ten plik jest źródłem prawdy dla organizacji sekcji Konto / Ustawienia / Preferencje w aplikacji.
Wszystkie decyzje dotyczące układu ustawień, kategorii, ekranów szczegółów oraz opcji użytkownika zapisujemy tutaj.

## Zasada główna
Ekran główny ustawień nie pokazuje wszystkich ustawień naraz.
Ekran główny ustawień pokazuje wyłącznie listę kategorii.
Każda kategoria jest osobnym kafelkiem albo elementem listy.
Po kliknięciu kategorii użytkownik przechodzi do osobnego ekranu szczegółów tej kategorii.
Na ekranie szczegółów użytkownik widzi dopiero konkretne ustawienia.

## UX/UI ustawień
Wygląd ekranu ustawień, kafelków kategorii, avatara, popupów i przejść opisuje `docs/appereance/UX_UI.md`.

## Główny ekran ustawień
Na górze ekranu widoczny jest profil agenta.

Główny ekran ustawień pokazuje następujące kategorie:
- Konto
- Powiadomienia
- System pracy - leadowanie
- Sprzedaż
- Dashboard
- Raporty
- Wygląd aplikacji
- Pomoc i informacje

## 1. Konto
Sekcja Konto zawiera:
- Imię i nazwisko
- Adres e-mail
- Numer telefonu opcjonalny
- Branża sprzedażowa
- Zmiana hasła
- Wyloguj
- Usuń konto

Usunięcie konta wymaga dodatkowego potwierdzenia.
Usunięcie konta wymaga potwierdzenia przez e-mail.
Z perspektywy aplikacji konto znika od razu po usunięciu.
Technicznie w bazie danych konto może mieć 30 dni karencji, ale agent nie powinien widzieć tej informacji w aplikacji.

## 2. Powiadomienia
Sekcja Powiadomienia zawiera:
- Opcje powiadomień: w aplikacji, push, e-mail
- Przypomnienia o spotkaniach
- Przypomnienia o klientach do telefonu
- Przypomnienia o klientach do podjechania
- Powiadomienia push włączone / wyłączone

Domyślnie włączone są powiadomienia w aplikacji.
Użytkownik może zaznaczyć kilka kanałów powiadomień jednocześnie.

## 3. System pracy - leadowanie
Sekcja System pracy - leadowanie zawiera:
- Początek tygodnia pracy
- Koniec tygodnia pracy
- Cel leadowania
- Cykl pracy: mieszany albo 2-dniowy
- Domyślny status nowego kontaktu

Domyślny status nowego kontaktu to Umówione spotkanie.
Cel leadowania może być ustawiany przed rozpoczęciem sesji leadowania, a docelowo także zapamiętywany jako preferencja użytkownika.

## 4. Sprzedaż
Sekcja Sprzedaż zawiera:
- Aktywne produkty
- Średni czas trwania spotkania sprzedażowego
- Początek dnia sprzedażowego
- Koniec dnia sprzedażowego
- Powiadomienia podczas spotkań sprzedażowych włączone / wyłączone

Domyślne godziny dnia sprzedażowego to 12:00-18:00.

## 5. Dashboard
Sekcja Dashboard zawiera ustawienia włączone / wyłączone:
- Personalizacja ekranu głównego
- Wybór widocznych sekcji
- Kolejność sekcji

Dashboard powinien mieć domyślny, sensowny układ bez konieczności konfiguracji.
Personalizacja Dashboardu ma pozwalać użytkownikowi decydować, które sekcje widzi i w jakiej kolejności.

## 6. Raporty
Sekcja Raporty zawiera:
- Adres e-mail do raportów
- Wysyłka raportów e-mail
- Raporty tygodniowe Premium
- Raporty miesięczne Premium

Raport zawiera:
- liczbę dodanych kontaktów
- liczbę umówionych spotkań
- liczbę podpisanych umów
- liczbę klientów dodanych do W realizacji
- liczbę spadów
- konwersję
- czas leadowania
- porównanie z poprzednim okresem

Automatyczne raporty e-mailowe zostają w zakresie funkcjonalnym aplikacji, ale bez blokowania obecnej pracy nad aplikacją.
Najważniejsze statystyki na start to: umówione spotkania, spisane umowy, klienci dodani do W realizacji oraz spady.
Spisana umowa liczy się w statystykach dopiero po dodaniu do W realizacji.
Tydzień w statystykach zaczyna się w poniedziałek.
Spad liczymy jako konwersję: (spisana umowa -> W realizacji) / status Spad i pokazujemy procentowo.

## 7. Wygląd aplikacji
Sekcja Wygląd aplikacji zawiera:
- Motyw jasny
- Motyw ciemny
- Motyw systemowy
- Wybór kolorystyki

## 8. Pomoc i informacje
Sekcja Pomoc i informacje zawiera:
- FAQ
- Centrum pomocy
- Kontakt
- Zgłoś problem
- Polityka prywatności
- Regulamin
- Wersja aplikacji

## Onboarding w ustawieniach
Na etapie projektowania aplikacja ma umożliwiać wyświetlenie podglądu onboardingu z poziomu ustawień konta, bez konieczności zakładania nowego konta.

## Dane i synchronizacja
Jeżeli ustawienia będą zawierały sekcję danych i synchronizacji, użytkownik może widzieć:
- status synchronizacji
- datę ostatniej synchronizacji
- informację, czy dane są bezpiecznie zapisane w chmurze

Możliwe przyszłe funkcje:
- eksport kontaktów do CSV
- eksport raportów
- import kontaktów, spraw W realizacji i statystyk z pliku
- automatyczna synchronizacja

Nie dodawaj użytkownikowi możliwości samodzielnego przywracania całej bazy danych z kopii zapasowej.
Przywracanie danych powinno być wykonywane po stronie administratora albo systemu po odpowiedniej wiadomości e-mail.
W razie potrzeby kontaktu z administratorem agent powinien zostać o tym poinformowany na dole ustawień.
