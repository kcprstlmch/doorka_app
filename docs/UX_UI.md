# Wersja mobilna
Aplikacja dzieli się na 2 główne sekcje.
UX/UI jest projektowane pod telefon i tablet.
Nie projektujemy oddzielnie widoków desktopowych; większe ekrany służą tylko do podglądu technicznego w trakcie budowy.
Do projektu Flutter zostały przeniesione assety z istniejącej aplikacji webowej:
- `assets/images/d2d-door-ka-logo.png`
- `assets/images/app-sidebar-logo.png`

Są to aktualne assety robocze marki Doorka.
Finalny UX/UI nadal będzie omawiany później na podstawie inspiracji, między innymi z Pinteresta.

## 1. Top bar
Po lewej logo Doorka, po prawej ikona dzwoneczka wraz z kropeczką czerwoną po jej prawej stronie przedstawiająca powiadomienia, które po kliknięciu wyświetlają listę z najważniejszymi informacjami dot. kontaktów, klientów itp, itd.

W przyszłości zostanie dodany jeszcze przycisk menu (na prawo od ikony dzwoneczka), po jego kliknięciu wyświetli się lista wszystkich najważniejszych sekcji. Element dodania w przyszłości

## 2. Panel dolny
Na nim są widoczne ikony danych sekcji, od lewej:
Strona główna (Dashboard z ikoną domu),
Kontakty (z ikoną kilku główek obok siebie),
Statystyka (z ikoną statystyki),
Konto (z inicjałami pierwszej litery imienia i pierwszej litery nazwiska)

Dodatkowo, po środku Przycisk szybkiej akcji (FAB), z zielonym tłem i białym plusem na środku (op najechaniu plus zamienia się w “X”. Po jego najechaniu wyświetla się nad nim popup z możliwością dodania:
Umów spotkanie (kontakt ze statusem umówione spotkanie),
Szybki kontakt (kontakt ze statusem szybki kontakt),
Dodaj kontakt (standardowa opcja dodania kontaktu)

W przyszłości dodane zostaną również takie funkcje jak: dodaj teren, włącz nagrywanie i wiele więcej. Ten przycisk ma na celu przyspieszenie całego procesu operowania aplikacją. Za jego pomocą agent jest w stanie zrobić wszystko, co wpłynie na jego efektywność w pracy.
Funkcje terenu/mapy oraz nagrywania są funkcjami przyszłościowymi i nie wchodzą w aktualny podstawowy zakres aplikacji.

## Sekcje / moduły
Aplikacja dzieli się na 4 sekcje

Główne sekcje to:
Strona główna (dashboard),
Kontakty, lista kontaktów, panel do zarządzania nimi,
Moi Klienci, lista klientów z tabeli `clients`,
Statystyka, automatyczne dane pobierane dot. umówionych spotkań / spisanych umów / klientów dodanych do Moi Klienci / spadów
Ustawienia / preferencje konta

## Kafelki kontaktów
Na kafelku kontaktu nie pokazujemy pełnego adresu ani numeru telefonu.
Numer telefonu jest reprezentowany przez zieloną ikonę słuchawki, jeśli numer istnieje.
Adres jest reprezentowany przez ikonę domku, która otwiera mapę/nawigację.
Pełne dane kontaktu, w tym adres i numer telefonu, są widoczne po wejściu w szczegóły kontaktu.
Kliknięcie całego kafelka kontaktu otwiera szczegóły kontaktu.
Nad listą kontaktów są kolorowe koła statusów z subtelną ikoną oka.
Kliknięcie koła chowa albo pokazuje kontakty danego statusu.
Kolejność kół można zmieniać, a lista kontaktów układa się według tej samej kolejności.
Kafelki kontaktów można przestawiać w obrębie ich statusu.
Listę kontaktów odświeża się gestem pociągnięcia w dół, bez osobnego przycisku odświeżania w nagłówku.
Przesunięcie kafelka kontaktu w prawo odsłania zielony przycisk dodania do Moi Klienci.
Przesunięcie kafelka kontaktu w lewo odsłania dwa przyciski akcji po prawej stronie: pomarańczowe Archiwum oraz czerwone Usuń.
Każda z tych akcji wymaga potwierdzenia komunikatem „Czy na pewno? Akcji nie można odwrócić.”
W zakładce Moi Klienci przesunięcie klienta w prawo odsłania akcję przywrócenia do kontaktów, również z potwierdzeniem.

## Dashboard - sekcja główna (tz. Strona główna aplikacji)

W tej sekcji agent widzi wszystkie najważniejsze informacje dot. jego pracy, tj.
1. Aktywny kafelek (czarne tło, białe napisy), który automatycznie po jego kliknięciu umożliwia dodanie spotkania (zielony przycisk, białe napisy), w tym kafelku (jeżeli mamy dzień umawiania spotkań) wyświetla się informacja o aktualnej statystyce danego dnia, np. Umówione spotkania: 3, cel na dziś 9. Pod spodem, jakiś cytat motywacyjny losowy wybierany z jakiejś ogólnodostępnej listy (najprawdopodobniej ja taką stworzę). Kafelek po kliknięciu przycisku Dodaj spotkanie nie znika

2. Umówione spotkania. Pod aktywnym kafelkiem lista umówionych już obecnie spotkań. 9 wierszy po 2 kafelki. 

Kafelek po lewej stronie to godzina, po dodaniu spotkania do dashboard można ten kafelek edytować poprzez kliknięcie na niego

Kafelek po prawej stronie to wszystkie informacje na temat klienta pobrane z Formularza - dodaj kontakt. 

### 3. Ostatnio dodane
Kontakty, które zostały ostatnio dodane. Niech domyślnie wyświetlają się 3 również, po 1 kafelek na 1 wiersz. Dodatkowo w tym kafelku mamy takie informacje jak:

Od lewej strony
Inicjały klienta,
Od góry:
Imię i nazwisko (pogrubione),
Numer telefonu,
Adres zamieszkania
Od prawej strony
Przycisk telefonu (zielony, na lewo),
Przycisk “x”

Po kliknięciu przycisku telefon aplikacja jest połączona z funkcją dzwonienia w telefonie i dzwoni do kontaktu.

Po kliknięciu “X” kontakt zostanie przeniesiony do archiwum, ale agent zostaje zapytany przez system poprzez Pop Up, czy aby na pewno chce przenieść kontakt do archiwum?

### 4. Statystyka
W tej części dashboard powinny się pojawiać:
informacje o poprzednim miesiącu (statystyka z Umówionych spotkań łącznie, spisanych umów, klientów dodanych do Moi Klienci i spadów),
informacje o obecnym miesiącu, (statystyka z umówionych spotkań, spisanych umów, klientów dodanych do Moi Klienci i spadów),
informacje o poprzednim tygodniu (te same dane co powyżej),
informacje o obecnym tygodniu (te same dane co powyżej)

Na podstawie tych danych powyżej agent jest w stanie stwierdzić na jakim etapie miesiąca / tygodnia jest i czy zrobił poprawę w odniesieniu do poprzednich okresów.

## Zasady wizualne -  ogólne
- Jeden główny CTA na ekran (najczęściej zielony
- Tekst przycisków opisuje akcję, nie nazwę funkcji (np. "Dodaj klienta" zamiast "Wyślij")
- Brak gradientów, błysków, efektów — płaski design
- Spójność kolorystyczna w całej apce
- Cień przycisku zawsze w kolorze przycisku (rgba), nie czarny
