# Dashboard

Ten plik jest źródłem prawdy dla sekcji Dashboard.
Opisuje mechanizmy, funkcje i zachowania ekranu głównego aplikacji.
Wygląd Dashboardu, kolory, kafelki i szczegóły UI opisują dodatkowo `docs/appereance/UX_UI.md` oraz `docs/appereance/design.md`.

## Rola sekcji
Dashboard jest stroną główną aplikacji.
Agent widzi tutaj najważniejsze informacje dotyczące bieżącej pracy, leadowania, najbliższych działań, ostatnich kontaktów oraz podstawowych wyników.

Dashboard nie powinien być tylko pustą makietą.
Powinien pokazywać informacje wynikające z kontaktów, spraw W realizacji i statystyk.

## Dzień leadowy i dzień sprzedażowy
Dzień leadowy generuje rekordy w CRM.
Dzień sprzedażowy konsumuje rekordy z CRM.
Każde umówione spotkanie z dnia leadowego ma przypisaną datę.
Dzień sprzedażowy filtruje CRM po dacie i pokazuje spotkania na dany dzień.

Pod top barem może być pokazywany kontekst dnia, np. `Dzień sprzedażowy 08.06 (pon.)`.
Data jest kotwicą dla akcji.
Agent nie powinien ręcznie wpisywać daty dla działań dnia, jeśli system może ją określić automatycznie.

## Przeterminowane leady
Jeśli agent nie nadpisał statusu spotkania, a kontakt ma przeszłą datę spotkania, aplikacja powinna oznaczyć go jako przeterminowany i wymagający akcji.
Aplikacja nie kasuje takiego kontaktu i nie zakłada automatycznie, co się wydarzyło.

## Główne elementy
Dashboard zawiera:
- aktywny kafelek leadowania
- szybkie akcje podczas sesji leadowania
- umówione spotkania / umówione na jutro
- szybkie notatki
- ostatnio dodane kontakty
- kafelek "W tym tygodniu"
- podstawowe statystyki i porównania okresów

## Aktywny kafelek leadowania
Aktywny kafelek jest głównym elementem Dashboardu podczas pracy w terenie.
Na obecnym etapie kafelek pokazuje dzień leadowania.

Kafelek pokazuje:
- aktualną datę i dzień tygodnia, np. `14.06 | Niedziela`
- główny tryb dnia, np. `Leadowanie`
- cel na dzisiaj, jeśli agent go ustali
- licznik czasu po rozpoczęciu sesji
- liczbę umówionych spotkań w sesji
- liczbę kontaktów dodanych w sesji

Agent nie może rozpocząć leadowania bez podania celu.
Jeśli agent kliknie Start bez ustawionego celu, aplikacja nie pokazuje popupu.
Zamiast popupu przycisk "Ustal cel" powinien zapulsować.

## Cel leadowania
Cel leadowania jest ustawiany przed rozpoczęciem sesji.
Po ustawieniu celu aktywny kafelek pokazuje cel na dzisiaj.
Po kliknięciu Start aktywny kafelek pokazuje dodatkowo:
- obecnie umówione spotkania w tej sesji
- kontakty dodane w tej sesji

Kontakty w sesji leadowania liczą kontakty dodane ze statusami:
- Szybki kontakt
- Zainteresowany
- Do podjechania
- Do zadzwonienia

## Sesja leadowania
Rozpocznij leadowanie uruchamia licznik czasu.
Licznik czasu jest pokazywany w formacie stopera `00:00:00`.
Agent może pauzować sesję.
Po kliknięciu "Przerwa" aplikacja pokazuje dwa przyciski:
- Wznów
- Koniec

Kliknięcie "Wznów" kontynuuje licznik.
Kliknięcie "Koniec" kończy aktualną sesję leadowania.

## Podsumowanie sesji
Po kliknięciu "Koniec" aplikacja pokazuje popup gratulujący zakończenia leadowania.
Popup pokazuje:
- liczbę umówionych spotkań
- liczbę zebranych kontaktów
- czas poświęcony na pracę
- czas przerwy
- cel sesji
- faktycznie osiągnięty wynik

Dane z popupu zakończenia sesji powinny automatycznie zapisywać się do statystyk agenta.

## Szybkie akcje
Pod aktywnym kafelkiem pojawiają się szybkie akcje:
- Umów spotkanie
- Szybki kontakt
- Szybka notatka
- Zapisz teren
- Przerwa, gdy sesja trwa

Akcja "Umów spotkanie" korzysta z tego samego formularza dodawania kontaktu, ale otwiera go od razu ze statusem Umówione spotkanie.
Akcja "Szybki kontakt" korzysta z tego samego formularza dodawania kontaktu, ale otwiera go od razu ze statusem Szybki kontakt.
Akcja "Szybka notatka" otwiera prosty input tekstowy bez dodatkowych pól.

## Szybka notatka
Szybka notatka pojawia się na Dashboardzie jako osobny kafelek albo lista notatek.
Po prawej stronie notatki znajduje się przycisk X.
Kliknięcie X usuwa szybką notatkę permanentnie z aplikacji.

## Umówione na jutro
Sekcja "Umówione na jutro" pokazuje kontakty ze spotkaniem zaplanowanym na kolejny dzień.
Po dodaniu umówionego spotkania przez akcję leadowania kontakt powinien pojawić się w tej sekcji, jeśli termin spotkania wypada jutro.
Sekcja ma mechanizm zwijania i rozwijania.

## Ostatnio dodane kontakty
Sekcja "Ostatnio dodane kontakty" pokazuje ostatnio zapisane kontakty.
Domyślnie wyświetla maksymalnie 3 kontakty.
Kliknięcie "Zwiń" chowa całą listę kontaktów.
Kliknięcie "Rozwiń" pokazuje ponownie maksymalnie 3 kontakty.
Po zwinięciu listy nie pokazujemy komunikatu pustego stanu, ponieważ kontakty nadal istnieją, tylko lista jest schowana.

## Kafelek "W tym tygodniu"
Dashboard pokazuje kafelek "W tym tygodniu" zamiast samego tekstu "Poprzedni tydzień jako porównanie".
Kafelek znajduje się na samym dole wśród kafelków Dashboardu.
Pokazuje aktualny wynik tygodnia oraz porównanie do poprzedniego tygodnia.
Przy liczbach widoczne są małe wartości porównawcze:
- różnica liczby
- procent względem poprzedniego tygodnia

Kafelek "W tym tygodniu" ma przycisk "Rozwiń" / "Zwiń".
Po zwinięciu zostaje widoczny sam nagłówek kafelka z akcją rozwinięcia.

### Główne metryki Dashboardu
Najważniejsze metryki Dashboardu na start to:
- ilość umów przeprocesowanych
- ilość spotkań umówionych
- ilość czasu w terenie w formacie godzin, minut i sekund

Te trzy metryki są największymi składowymi aplikacji.
Kafelek "W tym tygodniu" ma domyślnie pokazywać właśnie te wartości.
Domyślny zakres porównania to tydzień do poprzedniego tygodnia.
W przyszłości zakres porównania będzie można zmienić w ustawieniach.

Na obecnym etapie "umowy przeprocesowane" są liczone jako realizacje dodane w danym okresie.
Dokładna definicja tej metryki wymaga doprecyzowania, ponieważ może docelowo oznaczać także przejście klienta przez konkretne etapy realizacji.

## Zależność od rytmu dnia
Docelowo system powinien wiedzieć, czy dany dzień jest dniem:
- leadowania
- sprzedaży
- organizacji
- odpoczynku
- regeneracji

W dzień organizacji albo odpoczynku aktywny kafelek leadowania nie powinien się pojawiać.

## Powiązania z innymi sekcjami
Dashboard korzysta z danych z:
- Kontaktów
- W realizacji
- Statystyki
- Ustawień

Dashboard nie powinien dublować pełnych list ani pełnej analityki.
Ma pokazywać najważniejsze skróty i prowadzić agenta do działania.
