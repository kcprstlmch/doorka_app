# Design

Ten plik opisuje aktualny wygląd aplikacji Doorka na obecnym etapie prac.
Jest to roboczy snapshot design systemu: kolory, czcionki, kafelki, przyciski, paski, spacing i ogólne odczucie aplikacji.
Plik będzie później edytowany, gdy ustalimy finalny styl wizualny.

## Decyzja kierunkowa
Aplikacja ma być projektowana jak narzędzie terenowe dla agenta sprzedażowego, a nie jak dekoracyjny CRM.
Agent będzie używał jej szybko, często, czasem w słońcu, w aucie albo między spotkaniami.

Priorytetem są:
- czytelność
- szybkość skanowania informacji
- wyraźne statusy
- spokojne tło
- mocne, ale nieliczne CTA
- brak wizualnego chaosu

Doorka ma wyglądać profesjonalnie, konkretnie i roboczo.
Nie idziemy w ciemny, futurystyczny CRM ani w kolorowy SaaS.

## Ogólny kierunek
Aplikacja jest projektowana głównie pod telefon i tablet.
Nie projektujemy osobnych widoków desktopowych; większe ekrany służą tylko do podglądu technicznego w trakcie budowy.

Aktualny styl:
- jasny
- prosty
- użytkowy
- oparty o białe kafelki i delikatne linie
- z zielenią Doorka jako kolorem głównym
- bez ciężkich gradientów i dekoracyjnych ozdobników

Interfejs ma sprawiać wrażenie spokojnego narzędzia pracy dla agenta sprzedażowego, a nie strony marketingowej.
Zieleń Doorka jest kolorem akcji i marki, a nie dekoracją używaną wszędzie.

## Assety marki
Aktualne assety robocze marki Doorka:
- `assets/images/d2d-door-ka-logo.png`
- `assets/images/app-sidebar-logo.png`

Logo jest widoczne w top barze aplikacji.

## Czcionka
Docelowy font aplikacji: `Inter`.

Uzasadnienie:
- bardzo dobra czytelność na telefonie
- profesjonalny, aplikacyjny charakter
- dobrze działa w tabelach, listach, formularzach i kafelkach
- jest neutralny, więc nie konkuruje z danymi agenta

Alternatywy, jeśli Inter nie sprawdzi się wizualnie:
- `Manrope` - bardziej charakterystyczny, nadal czysty
- `IBM Plex Sans` - bardziej techniczny i poważny

Na ten moment rekomendacja: zaczynamy od `Inter`.

## Typografia
Nie używamy dużych, marketingowych nagłówków w ekranach roboczych.
Tekst ma być czytelny, prosty i szybki do przeskanowania.

Docelowa skala tekstu:
- tytuł ekranu szczegółowego: `22px`
- nagłówek sekcji albo kafelka: `17-18px`
- nazwa klienta albo kontaktu: `15-16px`
- standardowy tekst: `14px`
- opisy pomocnicze: `12-13px`
- małe metryki, etykiety i porównania: `11-12px`

Nie schodzimy poniżej `11px`, jeśli tekst ma być realnie czytany przez agenta.
Agent może używać aplikacji w terenie, więc zbyt mały tekst jest ryzykiem UX.

## Grubości tekstu
Obecnie w aplikacji jest dużo `FontWeight.w900`.
Docelowo ograniczamy bardzo ciężkie fonty, żeby interfejs był bardziej profesjonalny i mniej krzykliwy.

Docelowe zasady:
- najważniejsze liczby, wynik celu, mocny status: `FontWeight.w800`
- nagłówki sekcji i kafelków: `FontWeight.w700`
- zwykły tekst i wartości: `FontWeight.w500`
- tekst pomocniczy: `FontWeight.w400` albo `FontWeight.w500`
- `FontWeight.w900` tylko dla wyjątkowo mocnych elementów, np. krytyczny wynik, ważna liczba albo status wymagający natychmiastowej uwagi

Przykładowe rozmiary używane w aplikacji:
- małe etykiety: `9.5-12px`
- opisy i podpisy: `12px`
- nazwy kategorii ustawień: `15px`
- nagłówki w popupach / onboardingu: `18-22px`
- większe liczby w kafelkach: około `24px`

## Kolory główne
Kolory mają mieć funkcję.
Nie używamy kolorów jako dekoracji.
Każdy mocniejszy kolor powinien komunikować znaczenie: akcję, status, ostrzeżenie, sukces albo zmianę.

Docelowa paleta bazuje na obecnych kolorach aplikacji:

### Tło aplikacji
- Główne tło aplikacji: `#F7F4ED`
- Jasne tło kafelków/paneli: `#FAF9F5`
- Białe tło elementów i list: `#FFFFFF`

### Kolor marki / akcje pozytywne
- Główna zieleń Doorka: `#2F5D50`
- Jasna zieleń akcji pozytywnej: `#62BE72`
- Zielony akcent postępu/onboardingu: `#54D376`
- Bardzo jasne zielone tło ikon/inicjałów: `#E7EFE8`
- Jasne zielone tło elementów aktywnych: `#EAF2EF`

### Tekst
- Główny ciemny tekst: `#172019`
- Bardzo ciemne tło aktywnego kafelka: `#101512`
- Pomocniczy szary tekst: `#6A6F68`
- Jasny tekst na ciemnym tle: `#DDEADF`
- Bardzo jasny tekst na ciemnym tle: `#EAF3EC`

### Linie i obramowania
- Główna linia/border: `#E4E0D7`
- Delikatny separator: `#EDE9DF`
- Border inputów: `#D8D4CA`
- Jaśniejszy border kafelków: `#E2DED4`

### Statusy i akcje
- Błąd / usuwanie / negatywne akcje: `#D64545`
- Pomarańczowy / do podjechania: `#F0A202`
- Niebieski akcent: `#2563A9`
- Niebieski status zainteresowania: `#5B7CFA`
- Fioletowy status: `#7B61FF`
- Szary status: `#6D6A75`
- Ciemny status spad: `#2E2D2A`

## Zasady użycia kolorów
Zielony:
- główne akcje pozytywne
- rozpoczęcie działania
- potwierdzenie
- statusy pozytywne albo aktywne

Niebieski:
- akcje konfiguracyjne
- przykład: "Ustal cel"
- nie używać jako głównego koloru marki

Czerwony:
- usuwanie
- błędy
- przerwa / zatrzymanie / ryzyko
- decyzje wymagające uwagi

Pomarańczowy:
- do podjechania
- elementy pośrednie, które wymagają działania, ale nie są błędem

Szary:
- tekst pomocniczy
- status neutralny
- elementy drugorzędne

Czarny / bardzo ciemny:
- elementy o wysokim priorytecie
- nie nadużywać na dużych powierzchniach poza kluczowymi kafelkami

## Statusy kontaktów
Aktualne kolory statusów kontaktów:
- Umówione spotkanie: `#2F5D50`
- Zainteresowany: `#5B7CFA`
- Szybki kontakt: `#6D6A75`
- Do podjechania: `#F0A202`
- Do przedzwonienia: `#7B61FF`
- Niezainteresowany: `#D64545`
- Brak kontaktu: `#8A8F98`

## Statusy realizacji
Aktualne kolory etapów / statusów W realizacji:
- Spisana umowa: `#2F5D50`
- Finansowanie / etap finansowy: `#2563A9`
- Wpłacona zaliczka / etap gotówkowy: `#8A5A12`
- Telefon powitalny: `#5B7CFA`
- Umawianie montażu: `#F0A202`
- W trakcie montażu: `#7C3AED`
- Zamontowany / po montażu: `#147D64`
- Zgłoszony do ZEI: `#4B6584`
- Dotacja: `#0F766E`
- Spad: `#2E2D2A`

## Kształty i promienie
Domyślny promień większości elementów:
- kafelki: `8px`
- inputy: `8px`
- przyciski: `8px`
- kafelki kategorii ustawień: `8px`

Elementy okrągłe:
- avatar / inicjały: pełne koło
- małe znaczniki i progress bary: radius `999px`
- małe znaczniki statusu: pełne koło albo radius `999px`

Popup onboardingu ma większy promień:
- `18px`

## Kafelki i listy
Kafelki zwykle mają:
- białe albo prawie białe tło
- border `#E4E0D7`
- radius `8px`
- delikatny, użytkowy charakter

Nie budujemy ekranów z ciężkich, dekoracyjnych kart.
Karty służą do grupowania realnej informacji: kontaktów, ustawień, statystyk, aktywnej sesji lub spraw W realizacji.

## Top bar
Top bar:
- ma białe tło
- nie zmienia koloru przy scrollowaniu
- ma delikatną dolną linię `#E4E0D7`
- po lewej pokazuje logo Doorka
- po prawej pokazuje avatar albo inicjały handlowca
- kliknięcie avatara/inicjałów otwiera Konto/Ustawienia animacją wysunięcia z prawej strony
- panel Konto/Ustawienia przykrywa cały ekran, razem z topbarem i dolną nawigacją

## Dolny panel nawigacji
Dolny panel:
- ma białe tło
- ma górną linię `#E4E0D7`
- między elementami ma delikatne pionowe separatory
- odstępy między ikonami są mniejsze niż standardowo

Aktualne zakładki:
- Dashboard
- Kontakty
- Umówione
- W realizacji
- Statystyka

Konto nie jest zakładką w dolnym panelu.
Avatar albo inicjały agenta są widoczne w topbarze po prawej stronie, bez podpisu tekstowego.
Kliknięcie avatara/inicjałów otwiera pełnoekranowy panel Konto/Ustawienia.

Przycisk szybkiej akcji FAB:
- koncepcyjnie ma zielone tło i biały plus na środku
- po aktywacji plus może zamienić się w "X"
- po aktywacji ma pokazywać popup z szybkimi akcjami
- na obecnym etapie jest schowany, niewidoczny i nieklikalny

## Konto i ustawienia
Kafelek profilu na ekranie Konto ma wyróżniać się od pozostałych kafelków mocniejszym tłem.
Ekran Konto:
- pokazuje profil agenta na górze
- używa inicjałów w delikatnym zielonym tle albo zdjęcia profilowego
- na avatarze/inicjałach ma przyciemnioną nakładkę z ikoną aparatu

Główny ekran ustawień wizualnie jest prostą listą kategorii.
Każda kategoria:
- jest osobnym kafelkiem/listowym elementem
- ma nazwę
- nie pokazuje ikony po lewej
- nie pokazuje podtytułu
- ma strzałkę `>` po prawej, jeśli otwiera ekran szczegółów

Aktualne kategorie ustawień:
- Konto
- System pracy - leadowanie
- Sprzedaż
- Wersja aplikacji: 0.0.1

Kafelek wersji aplikacji jest informacyjny i nie musi mieć strzałki.

Po kliknięciu kategorii ekran szczegółów wsuwa się z prawej strony.
Przejścia w ustawieniach mają sprawiać wrażenie jednej, warstwowej przestrzeni.

## Onboarding
Podgląd onboardingu działa jako popup / warstwa nad aktualnym ekranem.
Popup:
- ma ciemny nagłówek `#172019`
- używa jasnego tła `#F7F4ED`
- ma promień `18px`
- pokazuje pasek postępu z zielonym akcentem `#54D376`

Przejścia między krokami onboardingu:
- mają lekkie przesunięcie
- mają przenikanie treści
- powinny być płynne i spokojne

## Dashboard
Dashboard nie ma dodatkowego nagłówka z nazwą sekcji.
Treść zaczyna się od właściwych modułów.

Kafelek szybkich akcji:
- jest pierwszym elementem Dashboardu
- zastępuje dawny aktywny kafelek leadowania
- nie ma przycisku Start, Przerwa, Koniec ani licznika czasu
- pokazuje cztery najważniejsze akcje agenta w siatce 2x2

Szybkie akcje:
- Umów spotkanie
- Dodaj kontakt
- Kontakt roboczy
- Dodaj własne

Przyciski szybkich akcji:
- zajmują po połowie szerokości rzędu
- mają równą wysokość
- mają delikatne odstępy między sobą
- korzystają z ikon i krótkich nazw

Szybka notatka:
- pojawia się na Dashboardzie jako osobny kafelek albo lista notatek
- po prawej stronie notatki ma przycisk X
- kliknięcie X usuwa notatkę permanentnie

Sekcja "Umówione na jutro":
- ma mechanizm zwijania i rozwijania
- po dodaniu umówionego spotkania kontakt może pojawić się w tej sekcji, jeśli termin wypada jutro

Sekcja "Ostatnio dodane kontakty":
- domyślnie pokazuje maksymalnie 3 kontakty
- ma przycisk "Rozwiń" albo "Zwiń" ze strzałką
- kliknięcie "Zwiń" chowa całą listę kontaktów
- kliknięcie "Rozwiń" pokazuje ponownie maksymalnie 3 kontakty
- po zwinięciu nie pokazujemy pustego stanu
- kontakty na liście mają być oddzielone subtelną poziomą kreską

Kafelek "W tym tygodniu":
- znajduje się na samym dole wśród kafelków Dashboardu
- pokazuje aktualny wynik tygodnia
- pokazuje porównanie do poprzedniego tygodnia
- przy liczbach widoczne są małe wartości porównawcze: różnica liczby oraz procent
- ma przycisk "Rozwiń" / "Zwiń"
- po zwinięciu zostaje sam nagłówek z akcją rozwinięcia

## W realizacji
Sekcja W realizacji ma wizualnie przypominać kolejkę / proces.
Kafelek realizacji pokazuje:
- etap aktualny
- etap kolejny
- pasek postępu
- dane klienta
- numer telefonu
- adres
- produkt
- typ klienta: gotówkowy albo na raty

W podglądzie nie pokazujemy zbędnych ikon domu i telefonu.
Widok ma dawać mentalne poczucie, że sprawa jest w trakcie procesowania.

## Kontakty
Kafelek kontaktu:
- nie pokazuje pełnego adresu ani pełnego numeru telefonu w podglądzie
- numer telefonu jest reprezentowany przez zieloną ikonę słuchawki, jeśli numer istnieje
- adres jest reprezentowany przez ikonę domku
- pełne dane są widoczne po wejściu w szczegóły

Kolorowe koła statusów:
- pokazują statusy kontaktów
- mają subtelną ikonę oka
- pozwalają chować i pokazywać kontakty danego statusu

Przesunięcia kafelka:
- w prawo: zielona akcja przeniesienia do W realizacji
- w lewo: czerwone Usuń

W zakładce W realizacji nie ma akcji powrotu sprawy do Kontaktów.

Ostatnio dodany kontakt w Dashboardzie pokazuje:
- inicjały klienta po lewej
- imię i nazwisko pogrubione
- numer telefonu
- adres zamieszkania
- po prawej przycisk telefonu
- po prawej przycisk X

Po kliknięciu przycisku telefonu aplikacja korzysta z funkcji dzwonienia w telefonie.
Po kliknięciu X kontakt ma zostać usunięty po potwierdzeniu popupem.

## Przyciski i inputy
Inputy:
- białe tło
- border `#D8D4CA`
- focus border `#2F5D50`
- radius `8px`

FilledButton i OutlinedButton:
- minimalna wysokość `52px`
- radius `8px`

Przycisk Google:
- białe tło
- tekst `#3C4043`
- border `#DADCE0`
- radius `4px`

## Wdrażanie typografii w aplikacji
Przy kolejnych zmianach UI należy dążyć do jednej wspólnej skali tekstu w motywie Fluttera.
Nie ustawiamy przypadkowych rozmiarów tekstu dla każdego kafelka osobno, jeśli da się użyć wspólnego stylu.

Rekomendowany podział:
- `titleLarge`: tytuły ekranów szczegółowych, około `22px`, `w700`
- `titleMedium`: nagłówki sekcji, około `18px`, `w700`
- `titleSmall`: nagłówki kafelków, około `16px`, `w700`
- `bodyLarge`: podstawowy tekst, około `14px`, `w500`
- `bodyMedium`: opisy i wartości pomocnicze, około `13px`, `w500`
- `labelSmall`: małe etykiety, około `11-12px`, `w500/w600`

Liczby i wyniki mogą mieć mocniejszy styl, ale powinny nadal wynikać ze wspólnej skali.

## Wdrażanie kolorów w aplikacji
Kolory powinny zostać opisane jako tokeny / stałe projektowe, zanim zaczniemy mocniej rozbudowywać UI.
Docelowo komponenty nie powinny ręcznie wpisywać przypadkowych kolorów.

Rekomendowane tokeny:
- `background`: `#F7F4ED`
- `surface`: `#FFFFFF`
- `surfaceSoft`: `#FAF9F5`
- `textPrimary`: `#172019`
- `textSecondary`: `#6A6F68`
- `border`: `#E4E0D7`
- `borderStrong`: `#D8D4CA`
- `brand`: `#2F5D50`
- `success`: `#62BE72`
- `info`: `#2563A9`
- `warning`: `#F0A202`
- `danger`: `#D64545`

Statusy mogą mieć osobną mapę kolorów, ponieważ ich znaczenie jest domenowe.

## Statystyka
Przełączniki zakresu statystyk:
- Łącznie
- Rok
- Miesiąc
- Tydzień
- Dzień

Przełączniki zakresu:
- mają zajmować 100% szerokości dostępnej kolumny
- są bez obramowania
- wyglądają jak sam tekst
- aktywny zakres jest pogrubiony

Kafelki statystyk:
- układają się po 2 w rzędzie
- każdy zajmuje około 50% szerokości dostępnej kolumny

Na obecnym etapie Statystyka pokazuje podstawowe kafelki:
- dodane kontakty
- W realizacji
- spisani klienci
- łączny czas leadowania
- liczba sesji leadowania

## Animacje i odczucie
Aplikacja ma unikać gwałtownych przeskoków.
Docelowe odczucie:
- płynne przechodzenie między ekranami
- warstwowe wchodzenie w szczegóły
- spokojne animacje
- mniej popupów, więcej sygnałów w interfejsie

Popupy są używane tylko wtedy, gdy naprawdę pomagają.
Jeśli da się użyć subtelnej animacji, pulsowania albo zmiany stanu elementu, preferujemy taki kierunek.

## Zasady wizualne ogólne
- Jeden główny CTA na ekran.
- Główny CTA jest najczęściej zielony.
- Tekst przycisków opisuje akcję, nie nazwę funkcji.
- Przykład: "Dodaj klienta" zamiast "Wyślij".
- Brak gradientów, błysków i zbędnych efektów.
- Design jest płaski i spójny kolorystycznie.
- Cień przycisku, jeśli występuje, powinien być w kolorze przycisku jako rgba, a nie czarny.

## Inspiracje i stan decyzji
Finalny UX/UI będzie omawiany później na podstawie inspiracji, między innymi z Pinteresta.
Część kolorystyki i stylu z istniejącej aplikacji webowej może służyć jako inspiracja wizualna, dopóki nie ustalimy finalnego UX/UI.
Nie ma jeszcze ostatecznie zamkniętych kolorów marki Doorka.

## Notatki do późniejszej edycji
Finalny styl wizualny nie jest jeszcze zamknięty.
Później będziemy dopracowywać:
- docelową czcionkę
- finalną paletę kolorów
- styl ikon
- styl kafelków
- tryb jasny / ciemny / systemowy
- inspiracje wizualne, między innymi z Pinteresta
