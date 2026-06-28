# Pytania

Ten plik jest miejscem na pytania, które pomagają doprecyzować działanie aplikacji.
Po odpowiedzi decyzje powinny zostać dopisane do właściwego pliku w docs.
Odpowiedziane pytania są usuwane z sekcji otwartych i przenoszone do sekcji Zdecydowane albo do właściwego pliku dokumentacji.
Tematy, na które nie ma jeszcze odpowiedzi, trafiają też do I_DONT_KNOW.md albo LATER.md.

## Otwarte

### Ostatnie decyzje przed startem
Czy aplikacja ma mieć ekran startowy/onboarding po rejestracji, czy od razu przechodzić do Strony głównej?

### Minimalny widok kontaktu
Jakie informacje dokładnie pokazujemy na kafelku kontaktu na liście?
Czy numer telefonu ma być widoczny na liście, czy tylko przycisk telefonu?

### Minimalny widok klienta
Czy kolor statusu realizacji ma być tłem całego kafelka, paskiem u góry, czy nagłówkiem?

### Główne zasady usuwania
Czy po 30 dniach karencji usunięcie konta usuwa wszystkie kontakty, klientów, dokumenty i statystyki?

### Dane prawne i zgody
Czy akceptacja regulaminu i polityki prywatności ma być zapisana w Supabase z datą i wersją dokumentu?
Czy w aplikacji ma być link do regulaminu i polityki prywatności w Moje konto?

### Dokumenty i storage
Czy limit 2 MB zostaje technicznie wykonalny po kompresji zdjęć?

### Zakres lokalizacji
Czy lokalizacja wraca dopiero przy funkcjach mapa/teren?

### Puste stany
Co agent widzi, gdy nie ma jeszcze żadnych kontaktów?
Co agent widzi, gdy nie ma jeszcze żadnych klientów w Moi Klienci?
Co agent widzi, gdy nie ma jeszcze statystyk?
Czy puste stany mają zachęcać do akcji, np. Dodaj pierwszy kontakt?

### Błędy i walidacja
Jak aplikacja ma komunikować błąd zapisu do Supabase?
Czy aplikacja ma pokazywać błędy pod konkretnymi polami, czy jako popup/toast?
Czy formularz ma blokować zapis, jeśli brakuje danych obowiązkowych?
Czy agent ma widzieć, które pole wymaga poprawy?

### Toasty i komunikaty sukcesu
Czy po dodaniu kontaktu ma pojawić się krótki komunikat "Kontakt dodany"?
Czy po zmianie statusu ma pojawić się komunikat z możliwością Cofnij?
Czy po przeniesieniu do Moi Klienci ma pojawić się opcja Przejdź do klienta?

### Cofanie akcji
Które akcje powinny mieć opcję Cofnij?
Czy cofnięcie zmiany statusu ma usuwać wpis aktywności, czy dodać nowy wpis cofnięcia?

### Uprawnienia przyszłych ról
Jakie dokładnie dane moderator może widzieć?
Czy moderator może edytować tylko status realizacji klienta, czy także dane klienta?
Czy manager może widzieć dane osobowe klientów, czy tylko statystyki?
Czy agent musi wyrazić zgodę na podpięcie managera do swoich statystyk?

### RLS i bezpieczeństwo danych
Czy dokumenty w storage też mają być przypisane do client_id albo client_product_id?
Czy moderator/manager ma mieć dostęp przez osobne polityki RLS?
Czy agent może eksportować wszystkie swoje dane?

### Dane wrażliwe
Czy numer telefonu i adres traktujemy jako dane wrażliwe w interfejsie?
Czy przy screenach/podglądzie aplikacji dane mają być maskowane?

### Wyszukiwanie
Po czym agent najczęściej będzie szukał kontaktu: imię, telefon, adres, status, notatka?
Czy wyszukiwarka ma działać globalnie po Kontaktach i Moi Klienci?

### Filtry kontaktów
Jakie filtry są najważniejsze na liście kontaktów?
Czy agent ma filtrować po statusie, dacie dodania, terminie kontaktu, dacie spotkania?
Czy mają być szybkie filtry typu Dzisiaj, Zaległe, Do telefonu, Umówione?

### Sortowanie kontaktów
Jaki jest domyślny porządek kontaktów?
Czy kontakty z najbliższym terminem kontaktu mają być na górze?
Czy kontakty ze statusem Umówione spotkanie mają być sortowane po dacie i godzinie?

### Priorytety kontaktów
Czy agent ma oznaczać kontakt jako ważny?
Czy kontakt oznaczony gwiazdką ma być traktowany jako priorytet?
Czy aplikacja ma sama podpowiadać kontakty wymagające działania?

### Dzwonienie
Czy aplikacja ma zapisywać fakt kliknięcia telefonu w aktywności?

### Do podjechania
Czy Do podjechania ma pojawiać się na Dashboardzie jako najbliższy kontakt?
Czy termin przy Do podjechania wybiera się kafelkami, kalendarzem, czy obiema metodami?

### Kalendarz
Czy kalendarz ma pokazywać tylko spotkania, czy też terminy kontaktu i podjechania?
Czy agent ma widzieć kalendarz tygodniowy, miesięczny, czy listę agenda?
Czy kalendarz ma integrować się z kalendarzem telefonu?

### Przypomnienia lokalne
Czy przypomnienia mają działać tylko przez aplikację/Supabase, czy też lokalnie na telefonie?
Czy przypomnienie ma być tworzone przy zapisie spotkania?
Czy agent może wyłączyć przypomnienie dla pojedynczego kontaktu?

### Historia statusów
Czy historia statusów ma pokazywać tylko ostatnie zmiany, czy całą historię?

### Edycja statusów
Czy agent może zmieniać kolejność statusów kontaktów?
Czy agent może ukrywać statusy domyślne, których nie używa?
Czy przywrócenie domyślnych statusów usuwa własne statusy, czy tylko przywraca ukryte?

### Kolory statusów
Czy kolory statusów mają być ustawiane ręcznie przez agenta?
Czy domyślne statusy mają mieć domyślne kolory?
Czy kolor statusu ma być widoczny jako pasek, tło karty, badge, czy nagłówek?

### Ulubiony kontakt i jakość
Agent może oznaczyć kontakt gwiazdką jako ulubiony / szczególnie ważny.
Gwiazdka jest widoczna obok nazwy kontaktu.
Kontakt może mieć też jakość/potencjał: `TOP`, `Mocny`, `Relacja`, `Słaby`.
Jakość wpływa na sortowanie kontaktów pod ulubionymi kontaktami.

### Produkty w kontaktach
Czy agent może zmienić produkt po przeniesieniu do Moi Klienci?

### Produkty w Moi Klienci
Czy produkt klienta ma wpływać na statusy realizacji?
Czy produkty mają mieć własne kolory albo ikony?

### Prowizja
Czy prowizja ma wchodzić do statystyk i raportów?

### Kwoty umowy
Czy aplikacja ma liczyć brutto z netto, czy agent wpisuje obie wartości?

### Finansowanie
Czy status "Zatwierdzone finansowanie" dotyczy tylko klientów ze sposobem realizacji Finansowanie?
Czy przy finansowaniu agent musi dodać umowę kredytową?
Czy finansowanie ma mieć osobny status oczekiwania na decyzję?

### Płatność gotówkowa
Czy przy Gotówce agent zawsze wybiera 50/50 albo Etapami?
Czy można zapisać Gotówkę bez rozpisania płatności?
Czy aplikacja ma przypominać o kolejnych etapach płatności?

### Dokumenty i limity
Czy pliki mają być prywatne per agent i klient?

### Trwałe usuwanie
Czy po 30 dniach karencji usunięcie konta usuwa wszystkie kontakty, klientów, dokumenty i statystyki?

### Statystyka spadów
Czy spad ma obniżać skuteczność agenta?
Czy spad ma być widoczny na Dashboardzie?

### Konwersja
Czy aplikacja ma pokazywać kilka rodzajów konwersji?

### Szybkie akcje na Dashboardzie
Dashboard nie ma juz sesji leadowania uruchamianej przyciskiem Start.
Aplikacja nie liczy czasu pracy w aktywnym panelu.
Na gorze Dashboardu sa stale widoczne szybkie akcje: Umow spotkanie, Dodaj kontakt, Kontakt roboczy i Dodaj wlasne.

### Motywacyjne elementy
Czy cytaty motywacyjne mają być w aplikacji?
Czy agent może je wyłączyć?
Czy komunikaty motywacyjne mają być neutralne, mocne sprzedażowo, czy bardziej spokojne?

### Import z telefonu
Czy agent ma mieć możliwość zaimportowania kontaktu z książki telefonicznej?
Czy aplikacja ma prosić o dostęp do kontaktów telefonu?
Czy dodany z telefonu kontakt musi dostać status?

### Aparat i zdjęcia
Czy aplikacja ma korzystać z aparatu tylko do dokumentów klienta?
Czy zdjęcia mają być kadrowane/skanowane automatycznie?
Czy agent może dodać zdjęcie domu/adresu do kontaktu, czy tylko dokumenty klienta?

### Lokalizacja
Do czego dokładnie aplikacja ma używać lokalizacji telefonu?
Czy lokalizacja ma pomagać przy adresie, mapie lub terenie?

### Regulaminy i zgody
Czy zgody mają być zapisane w Supabase?

### Usunięcie konta
Czy po 30 dniach karencji usunięcie konta usuwa wszystkie kontakty, klientów, dokumenty i statystyki?

### Kopia danych
Czy agent może pobrać kopię swoich danych?
Czy kopia danych ma zawierać dokumenty?
Czy kopia ma być generowana od razu, czy wysyłana e-mailem?

### Nazewnictwo
Czy w aplikacji używamy słowa "kontakt", "lead", czy oba?
Czy "Moi Klienci" zawsze piszemy wielkimi literami jako nazwę sekcji?

## Zdecydowane

### Supabase jako źródło prawdy
Supabase jest głównym źródłem danych aplikacji.
Aplikacja nie ma trzymać danych statycznie jako głównej bazy.
Przed zmianami w produkcyjnej bazie przygotowujemy backup albo eksport w folderze `/Users/kacstelmach/doorka/db_backup`.

### Rejestracja
Agent rejestruje się przez e-mail i hasło.
Na teraz do rejestracji konta wymagane są tylko e-mail i hasło.
Nie wymagamy imienia, nazwiska, telefonu ani innych danych profilu na etapie rejestracji.
Po rejestracji agent musi potwierdzić adres e-mail przed wejściem do aplikacji.
Agent pozostaje zalogowany, dopóki sam się nie wyloguje.
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło. Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.

### Kontakty i Moi Klienci
Kontakty i Moi Klienci są osobnymi sekcjami i osobnymi tabelami.
Docelowa techniczna nazwa tabeli klientów to `clients`.
Część danych wspólnych, na przykład adres albo numer telefonu, ma synchronizować się między nimi.
Istniejąca tabela `crm_leads` będzie traktowana jako stara tabela do migracji albo zastąpienia.
Po zmianie modelu trzeba podmienić odwołania Supabase w projekcie `/Users/kacstelmach/crm` na aktualne nazwy tabel.
Na etap 1 w schemacie `public` zostają tylko `profiles`, `contacts` i `clients`.

### Lista kontaktów
Lista kontaktów ma być grupowana po statusach, bo statusy są core kontaktu.

### Pola kontaktu
Pola kontaktu widoczne dla użytkownika to `contact_name`, `phone`, `address`, `status` oraz `note`.
Pozostałe pola kontaktu są techniczne i służą aplikacji, bazie danych, RLS, sortowaniu, filtrowaniu albo automatycznym wyliczeniom.
Kontakt można zapisać bez numeru telefonu albo bez adresu, ale wtedy w polu uwagi / notatki musi być informacja pozwalająca rozpoznać klienta.
Aplikacja może wykrywać potencjalne duplikaty po numerze telefonu.

### Uwagi / notatki kontaktu
Uwagi / notatki kontaktu są jednym polem tekstowym.

### Statusy kontaktów
Nieusuwalne i nieedytowalne statusy kontaktów to: Umówione spotkanie, Zainteresowany, Niezainteresowany, Do podjechania.
Status Do podjechania ma pole termin.

### Umówione spotkanie
Przy statusie Umówione spotkanie obowiązkowe są data, godzina i produkt.
Skala jakości spotkania nie jest używana.
Aplikacja domyślnie wybiera kolejny dzień oraz może ustawić godzinę 18:00.

### Do przedzwonienia
Termin kontaktu nie jest obowiązkowy.
Informacja o terminie może być zapisana w uwagi / notatki.

### Szybki kontakt
Szybki kontakt ma pola dane kontaktu oraz uwagi / notatki.
Szybki kontakt automatycznie ustawia status Szybki kontakt.

### Moi Klienci
Minimalne dane wymagane przy dodaniu do Moi Klienci to dane kontaktu, adres i nr telefonu.
Moi Klienci mają sekcje opisane w FUNCTIONAL_SPEC.md, w tym dokumenty, płatność i realizację.

### Notatki
Uwagi / notatki nie synchronizują się między kontaktem i klientem.
Na ten moment Moi Klienci nie mają pola uwagi / notatki analogicznego do kontaktów.
Wyjątek: przy statusie Spad można dodać uwagę / notatkę do klienta.
Aktywność statusów nie ma pola notatki.

### Statusy realizacji klientów
Domyślnym statusem realizacji klienta po dodaniu do Moi Klienci jest Spisana umowa.
Status "Do realizacji" nie jest obecnie domyślnym statusem realizacji klienta.
Status "Spad" jest finalną nazwą statusu przeznaczonego dla Moi Klienci.
Domyślne statusy realizacji to: Spisana umowa, Zatwierdzone finansowanie, Wpłacona część płatności, W trakcie montażu, Zamontowany, Zgłoszony do ZE, Zgłoszona dotacje, Spad.
Statusy realizacji klientów są edytowalne przez agenta.
Zmiana statusu realizacji ma zmieniać kolor nagłówka klienta albo całej sekcji danych klienta.
Klient ze statusem Spad zostaje obsługiwany w ramach W realizacji albo przyszłego przepływu zamykania spraw.

### Moderator i manager
W przyszłości mogą pojawić się konta typu moderator i manager.
Moderator może mieć dostęp do wybranych danych klientów i zmieniać statusy realizacji.
Manager może mieć dostęp do statystyk agentów oraz wybranych danych o kontaktach.

### Dzwonienie
Kliknięcie numeru telefonu ma korzystać z funkcji dzwonienia w telefonie.
Aplikacja nie pokazuje po zakończeniu połączenia pytania o zmianę statusu ani notatkę.

### Statystyki
Najważniejsze statystyki na start to umówione spotkania, spisane umowy, klienci dodani do Moi Klienci oraz spady.
Spisana umowa liczy się w statystykach dopiero po dodaniu do Moi Klienci.
Spad liczymy jako konwersję: (spisana umowa -> Moi Klienci) / status Spad i pokazujemy procentowo.
Tydzień w statystykach zaczyna się w poniedziałek.

### Szybkie akcje na Dashboardzie
Aktywny panel i licznik czasu leadowania zostaly usuniete z biezacej mechaniki.
Agent od razu korzysta z akcji na gorze Dashboardu, bez rozpoczynania i konczenia sesji.

### Produkty
Produkt przy Umówione spotkanie jest technicznym polem kontaktu.
Produkt nie przechodzi automatycznie do Moi Klienci.
Na etap 1 jeden wpis w `clients` oznacza jedną sprawę klienta z jednym produktem / umową.
Kolejny produkt tej samej osoby dodajemy na razie jako kolejny wpis w `clients`.
Domyślna lista produktów jest wstępnie zaakceptowana, ale będzie jeszcze dopracowywana.

### Istniejące dane produkcyjne
W etapie 1 czyścimy dotychczasowe kontakty i klientów.
W `profiles` zostaje konto `kcprstlmch@gmail.com` jako admin.

### Płatności i kwoty
Kwota netto i kwota brutto są wymagane przy danych umowy klienta.
Waluta to PLN.
Prowizja agenta jest ręcznym, opcjonalnym polem kwotowym.

### Widok kontaktu
Pełny adres kontaktu ma być widoczny dopiero w szczegółach, nie na liście.

### Widok klienta
Kafelek klienta w Moi Klienci pokazuje co najmniej: dane klienta, adres zamieszkania, produkt, kwotę netto, datę podpisania umowy i status klienta.

### Dashboard
Dashboard zaczyna się od kafelka szybkich akcji, bez aktywnego panelu czasu.
Dashboard ma pokazywać dzisiejsze i najbliższe kontakty do zadzwonienia albo podjechania.
Agent może zmienić godzinę spotkania bezpośrednio z Dashboardu.

### Nawigacja główna
Dolne menu ma zawierać: Strona główna, Kontakty, Statystyka, Moje konto.
Moi Klienci są osobną ważną sekcją, ale na teraz mają znajdować się w menu Moje konto.
To może się zmienić w przyszłości.

### Usunięcie konta
Agent może sam usunąć konto, ale wymaga to potwierdzenia przez e-mail.
Z perspektywy aplikacji konto znika od razu po usunięciu.
Technicznie konto ma 30 dni karencji w bazie danych, ale agent nie powinien widzieć tej informacji w aplikacji.

### Trwałe usuwanie
Przy trwałym usuwaniu aplikacja pokazuje popup potwierdzający. Nie wymagamy wpisywania słowa USUŃ.

### Przypomnienia
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Agent może wybrać Przypomnij później za 15 minut, maksymalnie.

### Mapy
Przy adresie ma być przycisk otwarcia zewnętrznej mapy bez pobierania lokalizacji agenta.
Agent może dzięki temu uruchomić nawigację bez ręcznego wpisywania adresu.

### Offline
Na teraz zakładamy, że internet jest dostępny.
Offline zostaje jako temat do późniejszego doprecyzowania.

### Podział płatny / bezpłatny
Na ten moment nie dzielimy funkcji na darmowe i płatne.
Aplikacja jest projektowana jako jedna całość funkcjonalna.

### Język aplikacji
Na ten moment aplikacja jest projektowana wyłącznie po polsku.

### UX/UI
Cały UX/UI zostaje do późniejszego omówienia na podstawie inspiracji, na przykład z Pinteresta.
