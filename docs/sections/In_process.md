# In Process

Ten plik jest źródłem prawdy dla sekcji W realizacji.
Opisuje mechanizmy, funkcje i zachowania spraw po podpisaniu umowy.
Wygląd kolejki i kafelków W realizacji opisują dodatkowo `docs/appereance/UX_UI.md` oraz `docs/appereance/design.md`.

## Nazwa sekcji
Robocza i zaakceptowana nazwa sekcji: W realizacji.
Sekcja W realizacji zastępuje wcześniejszą nazwę W realizacji.

## Rola sekcji
W realizacji nie jest klasyczną listą wszystkich klientów ani zwykłym CRM klientów.
Jest to kolejka aktywnych spraw po podpisaniu umowy:
- przed montażem
- w trakcie procesu
- w trakcie montażu
- na innym aktywnym etapie realizacji

Aplikacja ma służyć głównie do zarządzania procesami, a nie tylko do przechowywania listy klientów.

## Kiedy kontakt trafia do W realizacji
Kontakt trafia do W realizacji dopiero po decyzji agenta.
Nie dzieje się to automatycznie po samej zmianie statusu.

Po przeniesieniu kontaktu do W realizacji aplikacja tworzy albo aktualizuje rekord sprawy realizacyjnej w osobnej tabeli.
Kontakt znika z aktywnej listy Kontakty.

Minimalne dane wymagane przy dodaniu do W realizacji:
- dane kontaktu
- adres
- numer telefonu

## Pojęcia używane zamiennie
W kontekście W realizacji pojęcia mogą być używane zamiennie, jeśli odnoszą się do rekordu po podpisaniu umowy:
- klient
- sprawa realizacyjna
- kontakt ze spisaną umową
- klient w trakcie realizacji

## Dane sprawy W realizacji
Sprawa W realizacji powinna zawierać co najmniej:
- dane klienta
- adres zamieszkania
- numer telefonu
- produkt
- kwota netto
- data podpisania umowy
- status / etap realizacji
- typ klienta / forma płatności

Typ klienta / forma płatności:
- gotówkowy
- na raty

Agent może zmienić typ klienta / formę płatności w szczegółach sprawy W realizacji.

## Umowa
Zakładka / część Umowa powinna zawierać:
- data podpisania umowy
- numer umowy opcjonalny
- kwota netto
- kwota brutto
- prowizja agenta wpisywana ręcznie
- waluta PLN

Kwota netto i kwota brutto są wymagane przy danych umowy klienta.
Prowizja agenta jest ręcznym, opcjonalnym polem kwotowym.

## Płatność i sposób realizacji
Pole "Sposób realizacji" może mieć wartości:
- Gotówka
- Finansowanie

Jeżeli wybrano Finansowanie:
- nie pokazuj dodatkowych pól płatności
- dodaj możliwość dodania umowy kredytowej w maksymalnie 2 załącznikach
- limit rozmiaru załącznika wymaga doprecyzowania

Jeżeli wybrano Gotówka, pokaż dodatkowe pole "Sposób płatności":
- 50/50
- Etapami

Jeżeli wybrano 50/50:
- pojawiają się 2 pola do wpisania kwot albo procentów
- pola można edytować
- suma musi wynosić 100%

Jeżeli wybrano Etapami:
- pojawiają się 3 pola do wpisania kwot albo procentów
- agent sam definiuje przedziały procentowe
- system musi pilnować, aby suma wszystkich etapów wynosiła dokładnie 100%
- jeżeli suma nie wynosi 100%, formularz powinien wyświetlić błąd

Przykład etapów:
- 20% -> kwota wpłacona
- 30% -> kwota wpłacona
- 50% -> kwota wpłacona

## Dokumenty i zdjęcia
Celem dokumentów jest szybkie dodanie najważniejszych zdjęć lub dokumentów powiązanych z klientem.
Doorka nie ma być dyskiem Google ani biurowym CRM-em do przechowywania setek dokumentów.
Funkcja dokumentów ma być prosta, lekka i terenowa.

Założenia:
- dokumenty są przypisane wyłącznie do konkretnej sprawy / klienta
- sekcja dokumentów znajduje się na dole karty klienta
- użytkownik może dodać maksymalnie 2 pliki
- pliki mogą dotyczyć skanu faktury i umowy kredytowej
- aplikacja ma wspierać szybkie dodanie zdjęcia z telefonu albo aparatu, również w formie skanu

## Etapy realizacji
Każdy produkt / sprawa w W realizacji ma etapy realizacji.
Po przeniesieniu kontaktu do W realizacji system automatycznie przypisuje etap 1: Spisana umowa.

Etapy:
1. Spisana umowa
2. Po finansowaniu albo Wpłacona zaliczka
3. Po telefonie powitalnym
4. W trakcie umawiania montażu
5. W trakcie montażu
6. Zamontowany albo Po montażu
7. Zgłoszony do ZEI
8. Przyznana dotacja

Etap 2 zależy od typu klienta:
- klient na raty: Finansowanie / Po finansowaniu
- klient gotówkowy: Wpłacona zaliczka

## Historia etapów
Agent ma widzieć, na jakim etapie jest sprawa oraz jaki etap był wcześniej.
W szczegółach sprawy W realizacji agent ma widzieć historię zmian etapów/statusów z dokładną datą i godziną zmiany.
W szczegółach sprawy W realizacji wybór etapu ma być widoczny od razu, bez wchodzenia w tryb pełnej edycji danych klienta.
Zmiana etapu zapisuje się po wyborze z listy.

## Status Spad
Status Spad oznacza klienta, który po podpisaniu umowy i dodaniu do W realizacji rezygnuje.
Taki klient nadal liczy się jako dodany klient, ale dodatkowo zasila statystykę spadów.
Przy statusie Spad można dodać uwagę / notatkę do klienta.

Klient ze statusem Spad zostaje obsługiwany w ramach W realizacji albo późniejszego osobnego przepływu zamykania spraw.

## Zakończone realizacje
Po zakończeniu procesu, na przykład po montażu i domknięciu zgłoszeń, klient nie powinien dominować głównej listy W realizacji.
Zakończone realizacje powinny być dostępne niżej albo w osobnym, mniej eksponowanym miejscu aplikacji.

## Notatki
Uwagi / notatki nie są wspólnym polem kontaktu i realizacji.
Na ten moment uwagi / notatki występują przy kontaktach, a nie w W realizacji.
Wyjątkiem może być obsługa statusu Spad, gdzie agent może dopisać uwagę / notatkę.

## Relacja z Kontaktami
W zakładce W realizacji nie ma akcji powrotu sprawy do Kontaktów.
Jeżeli agent pomylił się przy przeniesieniu, klient powinien zostać usunięty i ewentualnie dodany ponownie jako nowy kontakt.

## Relacja ze Statystyką
Dodanie do W realizacji zasila statystykę spraw dodanych po spisanej umowie.
Spisana umowa nie jest statusem kontaktu.
Spisana umowa jest statusem realizacji po dodaniu do W realizacji.

Spad liczymy jako konwersję:
`(spisana umowa -> W realizacji) / status Spad`

Wynik pokazujemy procentowo.

## Supabase
Na etapie projektowania i zmian UI nie wykonujemy automatycznie migracji ani nadpisywania danych w Supabase.
Zmiany nazw, statusów i struktury bazy danych wymagają osobnej zgody użytkownika.
