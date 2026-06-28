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
Po lewej logo Doorka, po prawej avatar albo inicjały handlowca.
Po kliknięciu avatara/inicjałów ekran Konto/Ustawienia wysuwa się z prawej strony.
Panel Konto/Ustawienia jest pełnoekranowy: przykrywa topbar, dolny pasek i całą treść aplikacji.
Na dole top baru ma być delikatna pozioma linia oddzielająca menu od treści aktualnego ekranu.

## 2. Panel dolny
Na nim są widoczne ikony danych sekcji, od lewej:
Dashboard (z ikoną domu),
Kontakty (z ikoną kilku główek obok siebie),
Umówione spotkania,
W realizacji,
Statystyka (z ikoną statystyki)

Konto nie jest już osobną zakładką w dolnym panelu.
Konto / Ustawienia otwierają się po kliknięciu avatara albo inicjałów agenta w topbarze.

Element "Start" w dolnym panelu zostaje zastąpiony nazwą "Dashboard".
Odstępy między ikonami w dolnym panelu mają być mniejsze.
Między każdą sekcją dolnego panelu ma być widoczna delikatna pionowa kreska.
Na górze dolnego panelu ma być delikatna pozioma linia oddzielająca nawigację od treści ekranu.

Dodatkowo, po środku Przycisk szybkiej akcji (FAB), z zielonym tłem i białym plusem na środku (op najechaniu plus zamienia się w “X”. Po jego najechaniu wyświetla się nad nim popup z możliwością dodania:
Umów spotkanie (kontakt ze statusem umówione spotkanie),
Szybki kontakt (kontakt ze statusem szybki kontakt),
Dodaj kontakt (standardowa opcja dodania kontaktu)

Na obecnym etapie przycisk szybkiej akcji FAB jest schowany.
Nie jest widoczny i nie da się go kliknąć.

W przyszłości dodane zostaną również takie funkcje jak: dodaj teren, włącz nagrywanie i wiele więcej. Ten przycisk ma na celu przyspieszenie całego procesu operowania aplikacją. Za jego pomocą agent jest w stanie zrobić wszystko, co wpłynie na jego efektywność w pracy.
Funkcje terenu/mapy oraz nagrywania są funkcjami przyszłościowymi i nie wchodzą w aktualny podstawowy zakres aplikacji.

## Sekcje / moduły
Aplikacja dzieli się na 5 głównych sekcji widocznych w dolnym panelu.

Główne sekcje to:
Strona główna (dashboard),
Kontakty, lista kontaktów, panel do zarządzania nimi,
Umówione spotkania,
W realizacji, kolejka aktywnych spraw z tabeli `clients`,
Statystyka, automatyczne dane pobierane dot. umówionych spotkań / spisanych umów / spraw dodanych do W realizacji / spadów

Ustawienia / preferencje konta nie są sekcją dolnego panelu.
Są pełnoekranowym panelem otwieranym z topbara.

Ekrany głównych sekcji nie mają osobnego górnego nagłówka z nazwą sekcji.
Po wejściu w Dashboard, Kontakty, Umówione spotkania, Statystykę albo W realizacji nie pokazujemy dodatkowego wiersza/kafelka z tytułem ekranu.
Treść sekcji zaczyna się od razu od właściwego modułu albo listy.

## W realizacji
Sekcja W realizacji zastępuje roboczą nazwę Moi Klienci.
Nie jest to klasyczna lista wszystkich klientów ani CRM klientów.
Jest to kolejka aktywnych spraw po podpisaniu umowy: przed montażem, w trakcie procesu, w trakcie montażu albo na innym etapie realizacji.
Po wejściu w sekcję agent ma mentalnie widzieć, że sprawy są procesowane do konkretnego końca.
Kafelek realizacji powinien pokazywać kolejkę/proces, numer pozycji, aktualny status, kolor statusu i pasek postępu etapu.
W podglądzie kafelka W realizacji pod paskiem postępu pokazujemy nazwę produktu oraz typ klienta/formę płatności: gotówkowy albo na raty.
W szczegółach sprawy W realizacji agent może zmienić, czy klient jest gotówkowy, czy na raty.
Zakończone realizacje, na przykład po montażu i domknięciu zgłoszeń, nie powinny dominować głównej listy. Powinny być dostępne niżej albo w osobnym, mniej eksponowanym miejscu aplikacji.
Etapy realizacji:
1. Spisana umowa
2. Po finansowaniu albo Wpłacona zaliczka
3. Po telefonie powitalnym
4. W trakcie umawiania montażu
5. W trakcie montażu
6. Zamontowany albo Po montażu
7. Zgłoszony do ZEI
8. Przyznana dotacja
Etap 2 zależy od typu klienta: dla klienta na raty jest to Finansowanie, a dla klienta gotówkowego Wpłacona zaliczka.
W szczegółach sprawy W realizacji agent ma widzieć historię zmian etapów/statusów z dokładną datą i godziną zmiany.

## Konto i ustawienia
Szczegółowa organizacja ekranu Konto, ustawień i preferencji użytkownika znajduje się w `docs/sections/Settings.md`.

Ekran Konto pełni rolę centrum ustawień użytkownika.
Na górze ekranu widoczny jest profil agenta z inicjałami w delikatnym tle, nazwą użytkownika i adresem e-mail.
Kliknięcie inicjałów/awatara agenta otwiera opcję ustawienia zdjęcia profilowego.
Na inicjałach w ustawieniach ma być widoczna przyciemniona albo lekko zblurowana nakładka z ikoną aparatu, podobnie jak w popularnych kontach typu Google.
Po wybraniu zdjęcia profilowego avatar zastępuje inicjały w ustawieniach oraz w topbarze.

Ekran główny ustawień wizualnie powinien być prostą listą kategorii.
Każda kategoria jest osobnym kafelkiem albo elementem listy ze strzałką ">".
Nie pokazujemy wszystkich przełączników i opcji na ekranie głównym ustawień.
Na obecnym etapie ekran ustawień pokazuje tylko: Konto, System pracy - leadowanie, Sprzedaż oraz Wersja aplikacji 0.0.1.

Po kliknięciu kategorii ekran szczegółów powinien wsuwać się płynnie z prawej strony.
Przejścia w ustawieniach mają sprawiać wrażenie jednej spójnej, warstwowej przestrzeni.

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
Przesunięcie kafelka kontaktu w prawo odsłania zielony przycisk przeniesienia do kolejnego etapu.
Przesunięcie kafelka kontaktu w lewo odsłania czerwony przycisk Usuń.
Usunięcie wymaga potwierdzenia komunikatem „Czy na pewno? Akcji nie można odwrócić.”
W zakładce W realizacji nie ma akcji powrotu sprawy do Kontaktów.
Kafelek realizacji nie pokazuje zielonego przycisku "Kontakt" po przesunięciu w prawo.

## Dashboard - sekcja główna (tz. Strona główna aplikacji)

W tej sekcji agent widzi wszystkie najważniejsze informacje dot. jego pracy, tj.
1. Kafelek szybkich akcji na samej gorze Dashboardu.

Dashboard nie pokazuje juz aktywnego kafelka leadowania, przycisku Start, Przerwa, Koniec ani stopera czasu pracy.
Agent nie musi rozpoczynac sesji, zeby korzystac z aplikacji.

Pierwszy kafelek Dashboardu zawiera cztery glowne akcje:
- Umow spotkanie
- Dodaj kontakt
- Kontakt roboczy
- Dodaj wlasne

Akcje sa ulozone w siatce 2x2.
Kazdy przycisk zajmuje polowe szerokosci rzedu, z delikatnym odstepem miedzy kafelkami.
Akcja "Umow spotkanie" korzysta z tego samego formularza dodawania kontaktu, ale otwiera go od razu jako umowione spotkanie.
Akcja "Dodaj kontakt" otwiera formularz zwyklego kontaktu.
Akcja "Kontakt roboczy" sluzy do szybkiego dodania kontaktu bez typu i statusu.
Akcja "Dodaj wlasne" prowadzi do konfiguracji wlasnych statusow/ustawien kontaktow.

Sekcja "Umówione na jutro" ma mieć taki sam mechanizm zwijania i rozwijania jak "Ostatnio dodane kontakty".
Po dodaniu umówionego spotkania przez akcję leadowania kontakt powinien pojawić się w kafelku "Umówione na jutro", jeśli termin spotkania wypada jutro.

Dashboard pokazuje kafelek "W tym tygodniu" zamiast samego tekstu "Poprzedni tydzień jako porównanie".
Kafelek "W tym tygodniu" znajduje się na samym dole wśród kafelków Dashboardu.
Kafelek "W tym tygodniu" pokazuje aktualny wynik tygodnia oraz porównanie do poprzedniego tygodnia.
Przy liczbach widoczne są małe wartości porównawcze: różnica liczby oraz procent względem poprzedniego tygodnia.
Kafelek "W tym tygodniu" ma przycisk "Rozwiń" / "Zwiń".
Po zwinięciu zostaje widoczny sam nagłówek kafelka z akcją rozwinięcia.

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

Po kliknięciu “X” kontakt zostaje usunięty po potwierdzeniu przez popup.

### 4. Statystyka
W tej części dashboard powinny się pojawiać:
informacje o poprzednim miesiącu (statystyka z Umówionych spotkań łącznie, spisanych umów, spraw dodanych do W realizacji i spadów),
informacje o obecnym miesiącu, (statystyka z umówionych spotkań, spisanych umów, spraw dodanych do W realizacji i spadów),
informacje o poprzednim tygodniu (te same dane co powyżej),
informacje o obecnym tygodniu (te same dane co powyżej)

Na podstawie tych danych powyżej agent jest w stanie stwierdzić na jakim etapie miesiąca / tygodnia jest i czy zrobił poprawę w odniesieniu do poprzednich okresów.

## Zasady wizualne -  ogólne
- Jeden główny CTA na ekran (najczęściej zielony
- Tekst przycisków opisuje akcję, nie nazwę funkcji (np. "Dodaj klienta" zamiast "Wyślij")
- Brak gradientów, błysków, efektów — płaski design
- Spójność kolorystyczna w całej apce
- Cień przycisku zawsze w kolorze przycisku (rgba), nie czarny

## Statystyka
Przełączniki zakresu statystyk: Łącznie, Rok, Miesiąc, Tydzień, Dzień mają zajmować 100% szerokości dostępnej kolumny.
Przełączniki zakresu są bez obramowania, jako tekst.
Aktywny zakres jest pogrubiony.
Kafelki statystyk mają układać się po 2 w rzędzie, czyli po 50% szerokości dostępnej kolumny.
Na obecnym etapie statystyka pokazuje podstawowe kafelki:
- dodane kontakty
- W realizacji
- spisani klienci
- łączny czas leadowania
- liczba sesji leadowania
