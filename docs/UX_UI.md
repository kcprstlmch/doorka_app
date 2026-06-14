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
Dashboard (z ikoną domu),
Kontakty (z ikoną kilku główek obok siebie),
Statystyka (z ikoną statystyki),
Konto (z inicjałami pierwszej litery imienia i pierwszej litery nazwiska)

Element "Start" w dolnym panelu zostaje zastąpiony nazwą "Dashboard".
Odstępy między ikonami w dolnym panelu mają być mniejsze.
Między każdą sekcją dolnego panelu ma być widoczna delikatna pionowa kreska.

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

Aktywny kafelek ma być widoczny między nagłówkiem Dashboardu a kafelkami statystyk z kontaktami, klientami i spotkaniami.
Na tym etapie nie usuwamy Przycisku Szybkiej Akcji.
Docelowo przycisk akcji w aktywnym kafelku powinien zależeć od trybu pracy agenta: umawiania spotkań albo odbywania spotkań.
Aktywny kafelek dzieli się na dwie części: po lewej treść dnia, po prawej przycisk akcji.
Aktywny kafelek ma czarne tło.
Przycisk po prawej nie powinien być szeroki ani poziomy.
Przycisk Start ma mieć zielone tło, białą ikonę i biały napis.
Przycisk Start ma być jasnozielony, mniejszy i okrągły.
Ma wyglądać jak wyraźny element do kliknięcia, a nie klasyczny przycisk tekstowy.
Na etapie testowym aktywny kafelek pokazuje dzień leadowania.
Nagłówek kafelka pokazuje dzisiejszą datę i dzień tygodnia w formacie `14.06 | Niedziela`.
Główna treść kafelka to "Leadowanie".
Cel na dzisiaj nie pokazuje liczby, dopóki agent nie kliknie "Ustal cel" i nie poda wartości.
Przycisk "Ustal cel" ma być widoczny jako przycisk, a nie jako zwykły napis.
Przycisk "Ustal cel" ma mieć niebieskie tło, biały napis oraz ikonę check.
Docelowo system powinien wiedzieć z onboardingu albo ustawień, czy dany dzień jest dniem leadowania, sprzedaży, organizacji, odpoczynku albo regeneracji.
W dzień organizacji albo odpoczynku aktywny kafelek leadowania nie powinien się pojawiać.
Po kliknięciu przycisku rozpoczęcia leadowania pod aktywnym kafelkiem pojawiają się szybkie akcje:
- Umów spotkanie
- Szybki kontakt
- Szybka notatka
- Odwołaj spotkanie
Szybkie akcje pod aktywnym kafelkiem są ułożone w jednym rzędzie i zajmują całą szerokość ekranu.
Każda szybka akcja ma inne obramowanie.
Po kliknięciu przycisku Start aktywny kafelek pokazuje licznik czasu leadowania w formacie stopera `00:00:00`.
Licznik czasu pojawia się obok napisu "Czas leadowania" i jest oddzielony znakiem `|`.
Po rozpoczęciu leadowania przycisk Start zmienia się w przycisk "Przerwa" z ikoną pauzy.
Po kliknięciu "Przerwa" aplikacja pokazuje dwa przyciski: "Wznów" oraz "Koniec".
Kliknięcie "Wznów" kontynuuje licznik.
Kliknięcie "Koniec" kończy aktualną sesję leadowania.
Po kliknięciu "Koniec" aplikacja pokazuje popup gratulujący zakończenia leadowania.
Nagłówek popupu końca sesji ma kończyć się wykrzyknikiem.
Popup powinien gratyfikować agenta animacją celebracji/fajerwerków.
Popup podsumowania sesji pokazuje:
- liczbę umówionych spotkań
- liczbę zebranych kontaktów
- czas poświęcony na pracę
- czas przerwy
Dane z popupu zakończenia sesji powinny automatycznie zapisywać się do statystyk agenta.

Sekcja "Umówione na jutro" ma mieć taki sam mechanizm zwijania i rozwijania jak "Ostatnio dodane kontakty".

2. Umówione spotkania. Pod aktywnym kafelkiem lista umówionych już obecnie spotkań. 9 wierszy po 2 kafelki. 

Kafelek po lewej stronie to godzina, po dodaniu spotkania do dashboard można ten kafelek edytować poprzez kliknięcie na niego

Kafelek po prawej stronie to wszystkie informacje na temat klienta pobrane z Formularza - dodaj kontakt. 

### 3. Ostatnio dodane kontakty
Kontakty, które zostały ostatnio dodane. Domyślnie wyświetlają się maksymalnie 3 kontakty, po 1 kafelku na 1 wiersz.
W nagłówku tej sekcji po prawej stronie ma być przycisk "Rozwiń" albo "Zwiń" ze strzałką w górę albo w dół.
Kliknięcie "Zwiń" chowa całą listę kontaktów.
Kliknięcie "Rozwiń" pokazuje ponownie maksymalnie 3 kontakty.
Po zwinięciu listy nie pokazujemy komunikatu pustego stanu, ponieważ kontakty nadal istnieją, tylko lista jest schowana.
Kontakty na liście mają być oddzielone subtelną poziomą kreską.
Dodatkowo w tym kafelku mamy takie informacje jak:

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
