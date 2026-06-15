# Statistics

Ten plik jest źródłem prawdy dla sekcji Statystyka.
Opisuje mechanizmy, funkcje i zachowania statystyk agenta.
Wygląd kafelków i przełączników statystyk opisują dodatkowo `docs/appereance/UX_UI.md` oraz `docs/appereance/design.md`.

## Rola sekcji
Statystyka jest jedną z najważniejszych sekcji aplikacji.
Praca w sprzedaży bezpośredniej opiera się na mierzeniu aktywności, skuteczności i konwersji.

Agent nie wpisuje statystyk ręcznie.
Statystyki mają być wyliczane automatycznie z danych źródłowych.

## Źródła danych
Statystyki korzystają z danych z:
- Kontaktów
- W realizacji
- sesji leadowania
- statusów
- raportów / podsumowań

Głównym źródłem danych jest Supabase.
W Supabase trzymane są dane klientów, kontaktów, statusów, raportów i statystyk przypisanych do poszczególnych agentów.

## Najważniejsze metryki na start
Najważniejsze statystyki na start:
- umówione spotkania
- odbyte spotkania
- spisane umowy
- sprawy dodane do W realizacji
- spady
- łączny czas leadowania
- liczba sesji leadowania

Klasyczna statystyka sprzedaży bezpośredniej w OZE to 9/4/1:
- 9 umówionych spotkań
- 4 odbyte spotkania
- 1 spisana umowa

## Spisana umowa
Spisana umowa liczy się w statystykach dopiero po dodaniu sprawy do W realizacji.
Spisana umowa nie jest statusem kontaktu.
Jest statusem realizacji po dodaniu do W realizacji.

## Spad
Spad liczymy jako konwersję:
`(spisana umowa -> W realizacji) / status Spad`

Wynik pokazujemy procentowo.
Spad oznacza klienta, który po podpisaniu umowy i dodaniu do W realizacji rezygnuje.

## Czas leadowania
Czas leadowania jest liczony na podstawie sesji leadowania z Dashboardu.
Start -> Koniec to jedna sesja leadowania.

Po zakończeniu sesji:
- czas pracy dodaje się do łącznego czasu leadowania
- liczba sesji leadowania zwiększa się o 1
- dane z popupu podsumowania sesji zapisują się do statystyk

## Zakresy danych
Nad kafelkami statystyk znajduje się filtr zakresu danych:
- Łącznie
- Rok
- Miesiąc
- Tydzień
- Dzień

Tydzień w statystykach zaczyna się w poniedziałek.

## Kafelki statystyk
Ekran Statystyka jest oparty o przestawialne kafelki.
Kliknięcie kafelka otwiera szczegóły danej statystyki.

Na obecnym etapie kafelki pokazują:
- dodane kontakty
- W realizacji
- spisani klienci
- łączny czas leadowania
- liczba sesji leadowania

## Porównania okresów
Statystyki powinny umożliwiać porównanie aktualnego okresu z poprzednim.
Dashboard pokazuje skrót takiego porównania w kafelku "W tym tygodniu".

Raporty i podsumowania mogą pokazywać:
- poprzedni tydzień vs aktualny tydzień
- poprzedni miesiąc vs aktualny miesiąc

## Raporty
Raport zawiera:
- liczbę dodanych kontaktów
- liczbę umówionych spotkań
- liczbę podpisanych umów
- liczbę klientów dodanych do W realizacji
- liczbę spadów
- konwersję
- czas leadowania
- porównanie z poprzednim okresem

Automatyczne raporty e-mailowe zostają w zakresie funkcjonalnym aplikacji.
Szczegółowa organizacja ustawień raportów znajduje się w `docs/sections/Settings.md`.

## Późniejsze metryki
Na późniejszym etapie można dodać:
- średni czas spotkania sprzedażowego
- średni czas spotkania, gdzie klient jest zainteresowany
- statystyki jakościowe
- inne metryki skuteczności agenta

## Zasada
Na obecnym etapie ważniejszy jest sposób prezentacji statystyk niż finalna lista metryk.
