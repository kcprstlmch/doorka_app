# Decyzje projektowe

Ten plik zapisuje aktualne decyzje produktowe i techniczne, które doprecyzowują pozostałe dokumenty w folderze docs.

## Nadrzędność dokumentacji
Pliki `.md` w folderze `/docs` są podstawą tworzenia obecnej aplikacji Flutter.
Każda implementacja powinna być zgodna z dokumentacją, a nie tylko z istniejącą aplikacją webową.
Jeżeli istniejący projekt `/Users/kacstelmach/crm` ma inne nazwy, statusy, procesy albo uproszczenia niż dokumenty w `/docs`, to decyzje z dokumentacji mają pierwszeństwo.
Rozbieżności zapisujemy w `QUESTIONS.md`, `I_DONT_KNOW.md`, `LATER.md` albo w osobnym pliku audytu, zamiast bezrefleksyjnie przenosić je do Fluttera.

## Istniejąca aplikacja
Na stronie doorka.pl działa już aplikacja Doorka.
Projekt Supabase istnieje i nazywa się "CRM - agent sprzedazowy".
Przed tworzeniem nowych migracji trzeba najpierw zrobić audyt istniejącej aplikacji, obecnego schematu Supabase, tabel, danych i RLS.
Nie tworzymy lokalnych migracji w ciemno, jeśli można pracować bezpośrednio na istniejącym projekcie.
Lokalny folder istniejącej aplikacji webowej znajduje się w `/Users/kacstelmach/crm`.
Projekt `/crm` traktujemy jako źródło technicznego kontekstu, ale dokumentacja w `/docs` jest nadrzędna produktowo.
Nie przepisujemy webowej aplikacji 1:1 do Fluttera.
Przenosimy tylko sprawdzone elementy: assety marki, logikę Supabase, istniejące tabele jako punkt audytu, auth, storage oraz procesy zgodne z aktualną dokumentacją.
Flutter ma od początku korzystać z tej samej produkcyjnej bazy Supabase co doorka.pl.
Baza doorka.pl ma zostać docelowo dostosowana do statusów, danych i procesów zapisanych w `/docs`.
Zmiany struktury i czyszczenie danych wymagają ostrożności, ponieważ część danych w bazie jest do zachowania.
Konta agentów innych niż konto właściciela oraz większość danych testowych są prawdopodobnie do usunięcia, ale przed usunięciem trzeba przygotować listę i potwierdzić zakres.

## Porządkowanie tabel Supabase
Na etap 1 upraszczamy bazę Supabase.
W schemacie `public` zostają tylko tabele `profiles`, `contacts` i `clients`.
Nie tworzymy teraz osobnych tabel dla produktów, dokumentów, statusów ani historii statusów.
Stare tabele z webowego CRM są usuwane albo traktowane jako do zastąpienia.
SQL do ręcznego uruchomienia w Supabase SQL Editor znajduje się w `docs/SQL.md`.

## Zakres użytkowników
Obecnie aplikacja jest projektowana dla pojedynczych agentów sprzedaży bezpośredniej.
Panel firmowy, managerski albo widok wielu agentów nie jest aktualnym zakresem prac.
W przyszłości mogą pojawić się konta typu moderator i manager.
Moderator może mieć dostęp do wybranych danych klientów i zmieniać statusy realizacji.
Manager może mieć dostęp do statystyk agentów oraz wybranych danych o kontaktach, jeśli taki zakres zostanie zaprojektowany.

## Rejestracja
Agent może samodzielnie utworzyć konto w aplikacji.
Rejestracja podstawowa odbywa się przez e-mail i hasło.
Docelowo aplikacja powinna umożliwiać rejestrację i logowanie przez Google Authentication, ale konfigurację tego odkładamy na późniejszy etap.
Po rejestracji przez e-mail agent musi potwierdzić adres e-mail przed wejściem do aplikacji.
Przy rejestracji przez Google Authentication nie wymagamy dodatkowego potwierdzenia e-mail.
Agent pozostaje zalogowany, dopóki sam się nie wyloguje.
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło. Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.
Reset hasła nie dotyczy użytkowników logujących się przez Google.

## Kontakty i W realizacji
Sekcja wcześniej roboczo nazywana Moi Klienci zmienia kierunek produktowy na W realizacji.
Nie jest to lista wszystkich klientów ani klasyczny CRM klientów.
W realizacji to kolejka spraw po podpisaniu umowy: klienci przed montażem, w trakcie procesu, w trakcie montażu albo w innych aktywnych etapach realizacji.
Docelowa techniczna nazwa tabeli może nadal pozostać `clients`, ale produktowo traktujemy rekord jako sprawę realizacyjną klienta, a nie sam kontakt klienta.
Przycisk szybkiej akcji FAB zostaje na razie schowany w aplikacji. Nie usuwamy go koncepcyjnie, ale nie jest widoczny ani klikalny.
Po zakończeniu procesu, na przykład po montażu i domknięciu zgłoszeń, klient nie powinien dominować głównej listy W realizacji.
Zakończone sprawy powinny być dostępne w mniej eksponowanym miejscu aplikacji jako archiwum/lista klientów lub zakończone realizacje.
Część pól kontaktu i realizacji jest wspólna. Edycja wspólnego pola w jednej sekcji, na przykład adresu albo numeru telefonu, ma automatycznie aktualizować odpowiadające dane w drugiej sekcji.
Uwagi / notatki nie są wspólnym polem kontaktu i realizacji. Na ten moment uwagi / notatki występują przy kontaktach, a nie w W realizacji.
Na tym etapie jeden wpis w `clients` oznacza jedną sprawę realizacyjną klienta z jednym produktem / umową.
Jeśli ta sama osoba ma kolejny produkt, na razie dodajemy kolejny wpis w `clients`.
W kontekście W realizacji pojęcia klient, sprawa realizacyjna, kontakt ze spisaną umową oraz klient w trakcie realizacji mogą być używane zamiennie, jeśli odnoszą się do rekordu po podpisaniu umowy.
Rekord W realizacji ma mieć typ klienta albo formę płatności: gotówkowy albo na raty.
Typ klienta/formę płatności można zmienić w szczegółach sprawy W realizacji.

## Statusy
Statusy kontaktów i statusy realizacji klienta są osobnymi listami.
Status "Do realizacji" nie należy do statusów kontaktu. Może występować w obszarze W realizacji jako status realizacji podpięty bezpośrednio pod tabelę klientów/spraw.
Nieusuwalne i nieedytowalne statusy kontaktów to: Umówione spotkanie, Zainteresowany, Niezainteresowany, Do podjechania.
Status Do podjechania ma termin. Dokładny sposób wyboru terminu zostaje do doprecyzowania.
Domyślnym statusem realizacji klienta po dodaniu do W realizacji jest Spisana umowa.
Technicznie w tabeli `clients` domyślny status to `signed_contract`.
Każdy produkt/sprawa w W realizacji ma etapy realizacji.
Etap 1 jest bezwzględny: Spisana umowa.
Po przeniesieniu kontaktu do W realizacji system automatycznie przypisuje etap 1, czyli Spisana umowa.
Etap 2 może mieć wariant zależny od sposobu realizacji: Po finansowaniu albo Wpłacona zaliczka.
Jeśli klient jest na raty, etap 2 to Finansowanie.
Jeśli klient jest gotówkowy, etap 2 to Wpłacona zaliczka.
Etap 3: Po telefonie powitalnym.
Etap 4: W trakcie umawiania montażu.
Etap 5: W trakcie montażu.
Etap 6: Zamontowany albo Po montażu.
Etap 7: Zgłoszony do ZEI.
Etap 8: Przyznana dotacja.
Statusy realizacji klientów są edytowalne przez agenta.
Zmiana statusu realizacji klienta ma zmieniać kolor nagłówka albo całej sekcji danych klienta.
W podglądzie kafelka W realizacji nie pokazujemy produktu.
Agent ma widzieć, na jakim etapie realizacji umowy znajduje się sprawa oraz mieć wgląd w wcześniejsze etapy.
W szczegółach sprawy W realizacji ma być widoczna historia zmian etapów/statusów z dokładną datą i godziną zmiany.
Status "Spad" oznacza klienta, który po podpisaniu umowy i dodaniu do W realizacji rezygnuje.
Po ustawieniu statusu Spad aplikacja powinna pokazać przycisk Przenieś do archiwum.

## Supabase
Nazwy statusów, etapy realizacji i ewentualne zmiany struktury danych w Supabase mogą zostać nadpisane dopiero po wyraźnej zgodzie użytkownika.
Na etapie projektowania i zmian UI nie wykonujemy automatycznie migracji ani nadpisywania danych w Supabase.

## Aktywność
Na etap 1 nie tworzymy osobnych tabel historii statusów.
Aktualny status trzymamy bezpośrednio w rekordzie kontaktu albo klienta.

## Statystyki
Statystyki i raporty agenta mają być wyliczane na bieżąco z danych zapisanych w Supabase, a nie ręcznie utrzymywane jako statyczne wartości.
Najważniejsze statystyki na start to umówione spotkania, spisane umowy, sprawy dodane do W realizacji oraz spady.
Dodanie do W realizacji odbywa się przez przesunięcie kafelka kontaktu w prawo.
Spisana umowa nie jest statusem kontaktu; jest statusem realizacji po dodaniu do W realizacji.
Tydzień w statystykach zaczyna się w poniedziałek.
Spad liczymy jako konwersję: (spisana umowa -> W realizacji) / status Spad i pokazujemy procentowo.
Statystyki mają być wyliczane z danych źródłowych, a nie ręcznie wpisywane.
Ekran Statystyka ma być oparty o przestawialne kafelki.
Nad kafelkami znajduje się filtr zakresu danych: łącznie, rok, miesiąc, tydzień i dzień.
Kliknięcie kafelka otwiera szczegóły danej statystyki.
Na obecnym etapie ważniejszy jest sposób prezentacji statystyk niż finalna lista metryk.

## Sesja leadowania
Rozpocznij leadowanie uruchamia licznik czasu.
Agent może pauzować sesję.
Cel sesji obejmuje liczbę umówionych spotkań oraz liczbę zebranych kontaktów.
Po zakończeniu sesji ma pojawić się podsumowanie.
Funkcja Zamknij dzień pojawia się wtedy, gdy agent zrealizuje cel danego spotkania/sesji leadowania.

## Regulamin i polityka prywatności
Przy rejestracji agent musi zaakceptować regulamin oraz politykę prywatności.
Dokumenty regulaminu i polityki prywatności będą opracowywane w osobnych wątkach.

## Usunięcie konta
Agent może sam usunąć konto, ale wymaga to potwierdzenia przez e-mail.
Z perspektywy aplikacji konto znika od razu po usunięciu.
Technicznie w bazie danych konto może mieć 30 dni karencji, ale agent nie powinien widzieć tej informacji w aplikacji.

## Widoki list
Pełny adres kontaktu ma być widoczny dopiero w szczegółach, nie na liście.
Na kafelku kontaktu adres jest reprezentowany przez ikonę domku, która otwiera mapę/nawigację.
Numer telefonu nie jest tekstowo widoczny na kafelku; jeśli istnieje, pokazujemy ikonę słuchawki.
Kafelek klienta w Moi Klienci pokazuje co najmniej: dane klienta, adres zamieszkania, produkt, kwotę netto, datę podpisania umowy i status klienta.
Klient ze statusem Spad zostaje w głównej liście Moi Klienci, dopóki agent nie kliknie Przenieś do archiwum.

## Usuwanie danych
Trwałe usuwanie kontaktu lub klienta jest możliwe tylko z archiwum.
Przy trwałym usuwaniu aplikacja pokazuje popup potwierdzający. Nie wymagamy wpisywania słowa USUŃ.
Z głównej listy kontaktów użytkownik może przenieść kontakt do archiwum, ale nie usuwa go trwale.
Archiwum nie używa ikony kosza.
Kosz oznacza trwałe usunięcie i musi wymagać potwierdzenia.
W głównej liście kontaktów przesunięcie w lewo odsłania przyciski Archiwum i Usuń, ale sama czynność przesunięcia nie usuwa kontaktu.
Przesunięcie w prawo odsłania dodanie do Moi Klienci.
Każda akcja odsłonięta przez przesunięcie wymaga potwierdzenia.

## Przypomnienia
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Użytkownik może wybrać Przypomnij później za 15 minut, maksymalnie.

## Mapy
Przy adresie ma być przycisk otwarcia zewnętrznej mapy, żeby agent mógł szybko uruchomić nawigację do klienta bez ręcznego wpisywania adresu.

## Offline i online
Głównym źródłem danych aplikacji jest Supabase.
Tryb offline jest wymaganiem docelowym, ale jego dokładny zakres techniczny nie jest jeszcze przesądzony.
Założenie produktowe: jeśli agent straci internet, powinien móc dalej aktualizować dane klientów, kontaktów i statusów, a po odzyskaniu połączenia aplikacja ma automatycznie zsynchronizować zmiany z Supabase.
Aplikacja nie ma przechowywać danych statycznie jako głównego źródła prawdy. Lokalna pamięć służy tylko jako cache/kolejka zmian na czas braku internetu.
Na teraz zakładamy, że internet jest dostępny. Szczegółowy projekt trybu offline zostaje odłożony do późniejszej decyzji.

## Funkcje przyszłościowe
Mapa, teren pracy oraz nagrywanie są funkcjami przyszłościowymi.
Nie wchodzą w aktualny podstawowy zakres aplikacji.

## Model płatności
Model płatności, wersji bezpłatnej i wersji Premium nie jest jeszcze ustalony.
Na ten moment aplikacja ma być projektowana jako jedna całość funkcjonalna, bez rozdzielania funkcji na darmowe i płatne.

## Platformy
Aktualnym priorytetem jest Flutter na iOS i Android.
Panel webowy app.doorka.pl może zostać rozważony później.
UX/UI projektujemy pod telefon i tablet.
Duże ekrany desktopowe nie są aktualnym zakresem aplikacji; Chrome/macOS służą tylko jako techniczny podgląd podczas pracy.

## Język
Na ten moment aplikacja jest projektowana wyłącznie po polsku.
Rynek zagraniczny i inne języki mogą zostać rozważone później.
