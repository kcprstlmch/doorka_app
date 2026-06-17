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
- liczbę leadów dodanych w sesji

W aktywnym kafelku leadowania główne liczniki mają być pokazane obok siebie w formacie:
`Umówione: 4/9 | Leady: 6 | Czas: 01:12:33`

Agent nie może rozpocząć leadowania bez podania celu.
Jeśli agent kliknie Start bez ustawionego celu, aplikacja nie pokazuje popupu.
Zamiast popupu przycisk "Ustal cel" powinien zapulsować.

## Cel leadowania
Cel leadowania jest ustawiany przed rozpoczęciem sesji.
Po ustawieniu celu aktywny kafelek pokazuje cel na dzisiaj.
Po kliknięciu Start aktywny kafelek pokazuje dodatkowo:
- obecnie umówione spotkania w tej sesji
- leady dodane w tej sesji

Kontakty w sesji leadowania liczą kontakty dodane ze statusami:
- Umówione spotkanie
- Do podjechania

Szybka notatka nie liczy się do zebranych leadów.
Kontakt roboczy nie liczy się do zebranych leadów.

Reguły liczników:
- Umówione spotkanie dodaje +1 lead i +1 umówione.
- Do podjechania dodaje +1 lead i 0 umówionych.
- Kontakt roboczy dodaje 0 leadów i 0 umówionych.
- Szybka notatka dodaje 0 leadów i 0 umówionych.

Jeśli agent doda Umówione spotkanie bez kliknięcia Start, aplikacja tylko zapisuje kontakt.
Nie rozpoczyna automatycznie sesji ani cyklu.

## Codzienna realizacja celu
Najważniejsza potrzeba aplikacji dla agenta to codzienne prowadzenie go przez realizację celu w terenie.
Planowanie celu może dziać się rzadko, ale agent ma codziennie widzieć, jaki ma cel na dzisiaj i ile jeszcze brakuje.

Przykład:
- cel dnia: 9 umówionych spotkań
- obecnie: 4 umówione spotkania
- brakuje: 5 spotkań

Cel 9 spotkań dotyczy dnia umawiania spotkań, czyli leadowania.
Nie dotyczy dnia sprzedażowego.
W dniu sprzedażowym aplikacja liczy odbyte spotkania i spisane umowy, ale nie traktuje ich jako sztywnego celu dnia.

Według roboczej statystyki sprzedażowej 9 umówionych spotkań może przekładać się na około 4 odbyte spotkania i 1 sprzedaż, ale wynik sprzedażowy jest zmienny.
Agent może odbyć jedno spotkanie i spisać jedną umowę, dlatego dzień sprzedażowy nie ma takiego samego celu jak dzień leadowania.

Aktywny kafelek albo inny stale dostępny element Dashboardu powinien pomagać agentowi w pracy na bieżąco.
Agent nie powinien szukać funkcji w wielu miejscach, gdy jest w terenie.

### Szybkie dopisanie spotkania po zakończeniu dnia
Jeśli agent zakończył dzień leadowania, ale później odezwie się kontakt z kartki, telefonu albo SMS-a, agent nadal powinien mieć szybki dostęp do dodania spotkania.
Nie powinien musieć uruchamiać całej sesji leadowania tylko po to, żeby dopisać jedno umówione spotkanie.

Możliwe zachowanie:
- po zakończeniu sesji nadal dostępny jest szybki przycisk dodania umówionego spotkania
- spotkanie zapisuje się jako normalny kontakt ze statusem Umówione spotkanie
- spotkanie dolicza się do wyniku dnia, jeśli data dotyczy tego samego dnia albo bieżącej sesji rozliczeniowej

Jeśli agent dodaje spotkanie po czasie, aplikacja powinna umożliwić przypisanie go do odpowiedniego cyklu.
Docelowo aplikacja może podpowiadać cykl automatycznie na podstawie daty, ale agent powinien rozumieć, do czego spotkanie zostanie przypisane.

### Szybkie oznaczenie rezygnacji ze spotkania
Jeśli kontakt odwoła spotkanie, np. SMS-em rano, agent powinien szybko oznaczyć, że spotkanie zostało odwołane albo zrezygnowane.
To nie powinno wymagać długiego procesu edycji.

Możliwe zachowanie:
- przy kontakcie ze statusem Umówione spotkanie jest szybka akcja "Odwołane" albo "Rezygnacja"
- aplikacja aktualizuje status albo specjalne oznaczenie spotkania
- wynik dnia może zostać skorygowany
- historia kontaktu zapisuje informację o rezygnacji

Odwołane spotkania nie liczą się do wyniku.
Jeśli było `5/9`, a jedno spotkanie zostanie odwołane, wynik spada do `4/9`.
Oficjalnie interesuje nas wynik netto.

### Korekta wyniku dnia
Agent powinien móc korygować wynik dnia, gdy rzeczywistość zmieniła się po fakcie.
Przykłady:
- klient odwołał spotkanie
- agent dopisał spotkanie po zakończeniu leadowania
- kontakt przeniósł termin
- spotkanie zostało umówione poza aktywną sesją

To jest ważniejsze niż rozbudowane planowanie miesiąca.
Planowanie zostaje odłożone, ale codzienna realizacja i korekta celu są podstawową potrzebą aplikacji.

## Cykl pracy
Cykl pracy zaczyna się od leadowania i kończy po odbywaniu spotkań.
Na ten moment zakładamy cykl 2-dniowy:

- dzień 1: umawianie spotkań
- dzień 2: odbywanie spotkań

Cykl może być opisany zakresem dat, np. `Cykl 15-16.06`.
Cykl zawsze zaczyna się leadowaniem i kończy odbywaniem spotkań.
Pytanie, czy cykl może obejmować weekend, wymaga konsultacji z działającymi liderami sprzedaży.

Spotkania z dnia leadowania są rozliczane w dniu sprzedażowym jako odbyte albo nieodbyte.
Cykl kończy agent przyciskiem "Zakończ cykl".
Jeśli agent tego nie zrobi, cykl zamyka się automatycznie po końcu dnia, czyli po 00:00:00 kolejnego dnia.

## Liczniki
W mechanizmie core występują co najmniej dwa różne liczniki.

### Licznik umówionych spotkań
Licznik umówionych spotkań dotyczy celu leadowania.
Pokazuje wynik netto, czyli bez spotkań odwołanych.

Jeśli agent w poniedziałek umawia spotkanie na środę:
- poniedziałek dostaje +1 do pozyskanych leadów
- środa dostaje +1 do umówionych spotkań

Spotkanie umówione na dowolny przyszły dzień liczy się jako pozyskany lead w dniu, w którym zostało zdobyte, oraz jako umówione spotkanie w dniu, na który jest zaplanowane.
Jeśli spotkanie zostanie odwołane w trakcie dnia umawiania spotkań, wynik umówionych spotkań powinien spaść.
Jeśli spotkanie zostanie odwołane dopiero kolejnego dnia, agent nie miał już na to wpływu w trakcie leadowania, więc temat wymaga dokładniejszego modelu statystycznego.
Na teraz oficjalnie pokazujemy aktualny wynik netto.

Jeśli klient odwoła spotkanie przed jego rozpoczęciem, wpływa to na dzień sprzedażowy, ale nie zmienia wyniku dnia leadowania.
Jeśli agent kliknął już Start spotkania / Wszedłem, nie traktujemy tej sytuacji jak zwykłe odwołanie przed spotkaniem.
Przełożone nie liczy się do aktywnego wyniku do czasu ponownego umówienia i nie może zdublować wyniku tego samego kontaktu.

### Licznik pozyskanych leadów
Licznik "Pozyskane leady" liczy szerzej niż same umówione spotkania.
Może obejmować:
- umówione spotkania
- kontakty do podjechania

Szybka notatka nie liczy się jako pozyskany lead.
Kontakt roboczy nie liczy się jako pozyskany lead.
Kontakt Do podjechania liczy się jako pozyskany lead, ale musi mieć przynajmniej imię albo dane kontaktu, adres oraz ogólny termin.
Kontakt Niezainteresowany nie powinien być liczony jako pozyskany lead, ponieważ jest statusem po odbytym spotkaniu.

Pozyskane leady są metryką pomocniczą.
Najważniejsze liczniki core mechanizmu to:
- Umówione
- Odbyte
- Spisane umowy

Licznik pozyskanych leadów powinien być dostępny dziennie, tygodniowo, miesięcznie, rocznie i ogółem.

## Dzień sprzedażowy
Dzień sprzedażowy jest osobnym szerokim tematem.
Na ten moment wiadomo, że:
- nie ma sztywnego celu typu 9 spotkań
- dzień sprzedażowy zaczyna licznik odbytych spotkań od 0
- każde odbyte spotkanie dodaje 1 do statystyki odbytych spotkań
- spisana umowa dodaje 1 do osobnej statystyki umów
- etap W trakcie spotkania zaczyna się dopiero po kliknięciu przez agenta Start spotkania / Wszedłem

Docelowo aktywny kafelek dnia sprzedażowego może obsługiwać szybkie akcje typu:
- wszedłem na spotkanie
- nie wszedłem
- czas trwania spotkania
- spotkanie odbyte
- spisana umowa

To będzie osobny etap projektowania.

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
- liczbę zebranych leadów łącznie
- czas poświęcony na pracę
- cel sesji
- faktycznie osiągnięty wynik

Dane z popupu zakończenia sesji powinny automatycznie zapisywać się do statystyk agenta.

Po dniu sprzedażowym aplikacja pokazuje podsumowanie dnia sprzedażowego.
Następnie pokazuje Podsumowanie cyklu z gratulacjami.
Porównanie cyklu do poprzedniego cyklu obejmuje:
- Umówione spotkania
- Odbyte spotkania
- Liczbę leadów

Porównanie tygodnia albo dłuższego okresu obejmuje:
- Umówione spotkania
- Odbyte spotkania
- Liczbę leadów
- Spisane umowy

## Szybkie akcje
Pod aktywnym kafelkiem pojawiają się szybkie akcje:
- Umów spotkanie
- Do podjechania
- Kontakt roboczy
- Szybka notatka
- Zapisz teren
- Przerwa, gdy sesja trwa

Akcja "Umów spotkanie" korzysta z tego samego formularza dodawania kontaktu, ale otwiera go od razu ze statusem Umówione spotkanie.
Akcja "Do podjechania" otwiera formularz dopasowany do terminu albo przedziału podjechania.
Akcja "Kontakt roboczy" pozwala zapisać kontakt, który nie liczy się do statystyk.
Akcja "Szybka notatka" otwiera prosty input tekstowy bez dodatkowych pól.

## Szybka notatka
Szybka notatka pojawia się na Dashboardzie jako osobny kafelek albo lista notatek.
Po prawej stronie notatki znajduje się przycisk X.
Kliknięcie X usuwa szybką notatkę permanentnie z aplikacji.
Szybka notatka jest zwykłym tekstem wpisywanym przez agenta.
Agent może wpisać tam numer telefonu albo adres, jeśli chce.
Szybkiej notatki nie zamieniamy na kontakt.
Można ją tylko usunąć.
Nie wpływa na żadne liczniki.

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

W dzień organizacji albo odpoczynku aktywny kafelek leadowania nie powinien się pojawiać jako aktywne wezwanie do pracy.
Aplikacja powinna pokazać spokojny stan dnia wolnego zamiast pustki.
Aplikacja ma próbować sama rozpoznać typ dnia, ale może też zapytać agenta o potwierdzenie.

## Powiązania z innymi sekcjami
Dashboard korzysta z danych z:
- Kontaktów
- W realizacji
- Statystyki
- Ustawień

Dashboard nie powinien dublować pełnych list ani pełnej analityki.
Ma pokazywać najważniejsze skróty i prowadzić agenta do działania.
