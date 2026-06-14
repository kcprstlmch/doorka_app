# Dashboard - co się w nim znajduje

Ostatnio dodane kontakty - max 3,
Statystyka - tabela przedstawiająca poprzedni tydzień i aktualny, z informacjami tj.: Umówione spotkania, spisane umowy, klienci dodani do Moi Klienci i spady



DZIEŃ LEADOWY                    DZIEŃ SPRZEDAŻOWY
─────────────────────            ─────────────────────
Odwiedzone drzwi                 Spotkanie 
  ├── Właściciel był               ├── Zamknięte
  │     ├── (brak efektu)          ├── Zainteresowany (nie teraz)
  │     ├── Zebrany kontakt        └── Odmowa
  │     └── Umówione spotkanie
  ├── Brak właściciela
  │     ├── Zebrany kontakt
  │     └── (brak efektu)
  └── Karteczka

## Relacja między dniami
Dzień leadowy generuje rekordy w CRM
Dzień sprzedażowy konsumuje rekordy z CRM
Każde "umówione spotkanie" z dnia leadowego ma przypisaną datę automatycznie pobieraną z serwera
Dzień sprzedażowy filtruje CRM po dacie i pokazuje spotkania na dany dzień
## Kontekst dnia — UI
Pod top barem wyświetlana jest data dnia: "Dzień sprzedażowy 08.06 (pon.)"
Data jest kotwicą dla wszystkich akcji — agent nie wpisuje daty ręcznie
Każda akcja wykonana w widoku dnia zapisuje się automatycznie pod tą datą
Dotyczy zarówno dnia leadowego jak i sprzedażowego
## Przeterminowane leady
Jeśli agent nie nadpisał statusu spotkania — kontakt zostaje w stanie "zaplanowane" z przeszłą datą
Aplikacja wyłapuje to i sygnalizuje wprost jako "przeterminowane — wymaga akcji"
Nie kasuje kontaktu, nie zakłada co się stało

## Zakładka Aktywność
Historia zmian statusów danego kontaktu wyświetlana w sekcji Kontakty po wejściu w dany kontakt 
Po wejściu w kartę konkretnego kontaktu agent powinien widzieć sekcję „Aktywność”, w której automatycznie zapisuje się chronologiczna historia wszystkich zmian statusów tego kontaktu.
Aktywność dotyczy historii zmian statusów, a nie każdej edycji danych kontaktu.
W Supabase w głównym rekordzie kontaktu zapisywany jest obecny status kontaktu, a historia zmian statusów może być przechowywana w osobnej tabeli aktywności.
Każdy wpis w aktywności powinien zawierać co najmniej:
poprzedni status,
nowy status,
datę i godzinę zmiany,
Przykład:
10.06, 18:42 “Umówione spotkanie” na „Do obdzwonienia” Notatka: BZK. Zadzwonić 10.07, gdy syn otrzyma trzecią wypłatę.
Aktywność nie jest osobnym zadaniem ani statusem. Jest automatycznie tworzoną historią tego, co działo się z kontaktem w czasie.
W karcie leada lub klienta użytkownik może zmienić jego aktualny status.
Proces zmiany statusu powinien wyglądać tak:
Użytkownik klika aktualny status.
Wybiera nowy status z listy.
System pokazuje podsumowanie:„Zmiana statusu z [stary status] na [nowy status]”.
Użytkownik musi kliknąć przycisk „Zatwierdź”.
Dopiero po zatwierdzeniu nowy status zostaje zapisany.
Zmiana automatycznie pojawia się w sekcji „Aktywność”, która jest historią zmian statusów danego leada lub klienta.
Zmiana statusu nie może zapisywać się automatycznie po samym kliknięciu, aby ograniczyć przypadkowe błędy. Po zatwierdzeniu można dodatkowo przez kilka sekund pokazać opcję „Cofnij”.
## Formularz dodawania kontaktu
Zaimplementuj formularz dodawania leada lub klienta zgodnie z poniższą logiką i układem. WSZYSTKIE statusy mogą być edytowane w dowolny dla agenta sposób, nie ma stałego przypisanego statusu do klienta. Agent również może przywrócić domyślne statusy poprzez wejście w ustawienia -> preferencje agenta -> statusy kontaktów -> przywróć domyślne.
Tak naprawdę wszystko można edytować w tej aplikacji jeśli chodzi o informację. Jeden agent może chcieć mieć napisane imię i nazwisko, a inny dane klienta. Wybór danych dot. klientów ma być dowolny.

W bazie danych Supabase ma być jedynie informacja domyślna dotycząca klienta, w sensie takim, że domyślnie kolumna powinna się nazywać na przykład phone_numer, ale dla agenta w aplikacji może się nazywać Rozmiar buta.

Są jednak statusy domyślne, których agent nie może edytować, tj. Umówione spotkanie, Niezainteresowany, do przedzwonienia oraz szybki kontakt.

Podstawowe dane, które są na stałe przypisane do kontaktu to:
Dane klienta
Adres
Nr telefonu
Uwagi / notatki

Podstawowe pola przy zwykłym dodaniu kontaktu to: dane kontaktu, adres, nr telefonu, status oraz uwagi / notatki.
Kontakt można zapisać bez numeru telefonu albo bez adresu, ale wtedy w polu uwagi / notatki musi znajdować się informacja pozwalająca agentowi rozpoznać klienta.
Aplikacja może wykrywać potencjalne duplikaty kontaktów po numerze telefonu.

Lead lub klient może mieć tylko jeden aktualny status. Domyślny status przy tego rodzaju kontaktu to Umówione spotkanie.
Kontakty są głównie dzieleni ze względu na status. Rozróżniamy 8 głównych statusów, z możliwością dodania indywidualnie przypisanego indywidualnie do danego agenta
Umówione spotkanie
Zainteresowany
Szybki kontakt
Do podjechania
Do przedzwonienia
Niezainteresowany
Brak kontaktu
Każdy z kontaktów, do którego jest przypisany status ma oddzielne dodatkowe pola.
Nieusuwalne i nieedytowalne statusy kontaktów to: Umówione spotkanie, Zainteresowany, Niezainteresowany, Do podjechania.
Kontakt dodaje się do Moi Klienci przez przesunięcie kafelka w prawo.
### Status - Umówione spotkanie
Po wybraniu statusu „Umówione spotkanie” pokaż drugi wiersz zawierający cztery listy rozwijane.
Pola:
Data
Godzina
Produkt
Jakość
Data, godzina i produkt są obowiązkowe.
Jakość nie jest obowiązkowa.
Aplikacja domyślnie wybiera kolejny dzień jako datę spotkania.
Aplikacja domyślnie może ustawić godzinę 18:00.
Docelowo lista godzin spotkań ma być pobierana z ustawień agenta dotyczących standardowych godzin umawiania spotkań.
#### 1. Lista rozwijana “Data”
Lista Dzień tygodnia zawiera daty kalendarzowe zaczynające od dnia kolejnego:
#### 2. Lista rozwijana “Godzina”
Lista Godzina zawiera pola do wyboru godziny spotkania.
#### 3. Lista “Produkt”
Lista Produkt zawiera:
PV + ME
ME
UPSELL
Dach
Pompa ciepła
Turbina Wiatrowa
Czyste Powietrze
#### 4. Lista jakości
Lista Jakość zawiera:
S
M
L
XL
### Status - Do przedzwonienia
Status - do zadzwonienia zawiera dodatkowe informacji w postaci Termin kontaktu. Jest on ręcznie wybierany przez agenta, ale jest możliwość również dopisania dodatkowo własnego. Raz dopisany zostaje na zawsze. Można wybrać tylko jeden. 
Termin kontaktu jest automatycznie dodawany do bazy danych Supabase, w którym trzymana jest informacja o terminie kontaktu. Termin kontaktu może być zmieniany na potrzeby agenta. Każdy kafelek, który jest wybrany przez agenta może zostać edytowany w dowolny dla niego sposób, kafelki mają tylko i wyłącznie pomagać w wyborze terminu.
Termin kontaktu nie jest obowiązkowy. Informacja o terminie może zostać zapisana w uwagi / notatki.
Domyślne to:
Jutro,
za 2 dni,
w przyszłym tygodniu,
w przyszłym miesiącu,
19.06
Domyślne pola zostają takie same.
### Status - Do podjechania
Status Do podjechania jest obowiązkowym statusem kontaktu bez możliwości edytowania jego nazwy.
Status Do podjechania ma pole termin.
Dokładny sposób wyboru terminu, kafelki albo kalendarz, wymaga doprecyzowania.
### Status - Szybki kontakt
Status, za pomocą którego agent może dodać, tz. Szybki kontakt i podczas umawiania spotkań dodać podstawowe informacje do kontaktu. To jest jedyny kontakt, który wybiera agentowi takie informacje do dodania jak: Dane klienta i Nr telefonu. Pole Adres oraz Uwagi / notatki zostają schowane.
To jest kontakt, który agent zapisuje w momencie, kiedy nie ma osób decyzyjnych i otrzymuje nr telefonu od np. żony do męża, który nie może aktualnie odebrać telefonu, ale może go odebrać za kilka godzin, wtedy agent zapisuje nr telefonu do męża i dzwoni za kilka godzin. Rozmowa odbywa się przy płocie i pod wpływem presji agent dodaje kontakt do aplikacji.
Aktualna decyzja: Szybki kontakt ma pola dane kontaktu oraz uwagi / notatki.
### Status - Niezainteresowany
Po wybraniu tego statusu powinien pojawić się czerwony przycisk, który umożliwi agentowi przeniesienie klienta do zakładki Archiwum. Kontakt jednocześnie powinien zostać usunięty z zakładki Kontakty.
Nie dodawaj wartości tego przycisku do Supabase, niech on będzie funkcjonalny tylko w zakresie działania aplikacji
### 6. Automatyczne uzupełnianie pola „Uwagi / notatki”
Po wybraniu dnia, godziny, produktu oraz jakości system automatycznie tworzy nagłówek i umieszcza go na początku pola „Uwagi / notatki”.
Format:
09.06 (wt.), 12:00 | PV + ME | XL | 
Agent może dopisać własną treść bezpośrednio po automatycznym nagłówku.
Przykład:
09.06 (wt.), 12:00 | PV + ME | XL — obecni oboje małżonkowie, bardzo mili Państwo
Wszystkie wybrane informacje mają być widoczne wyłącznie w samym polu „Uwagi / notatki”. Pole uwagi / notatki można dowolnie edytować w dowolnym momencie ręcznie. Można to zrobić poprzez pola formularza wchodząc ponownie w kafelek danego klienta.

## Sekcja - Kalkulator
Usuń z projektu całą sekcję „Kalkulator”.
Założenie biznesowe: W aplikacji Doorka nie będzie kalkulatora ofertowego, ponieważ każda firma ma własne cenniki, produkty, zasady wyliczeń i aktualizacje. Doorka nie ma zastępować firmowych kalkulatorów ani integrować się z kalkulatorami wszystkich firm. Aplikacja ma skupiać się na organizacji pracy agenta, klientach, statusach, spotkaniach i prowizji, a nie na wyliczeniach ofertowych.
Zakres zmian:
Usuń wszystkie widoki, komponenty, przyciski, linki, zakładki i elementy menu związane z kalkulatorem.
Usuń routing/ścieżki prowadzące do kalkulatora.
Usuń wszystkie pliki, komponenty, helpery, typy, modele, serwisy i funkcje bezpośrednio powiązane z kalkulatorem.
Usuń z bazy danych tabele, kolumny, migracje, seedy i relacje stworzone wyłącznie pod kalkulator.
Nie usuwaj funkcji związanych z klientami, statusami, spotkaniami, notatkami, prowizją, aktywnością kontaktu ani organizacją pracy agenta.
Usuń wszystko co związane z Kalkulator w bazie danych w supabase za pomocą SQL
Po zmianach aplikacja ma nie zawierać żadnej osobnej sekcji kalkulatora ani informacji sugerujących, że Doorka liczy oferty lub zastępuje kalkulatory firmowe.

## Sekcja - W realizacji
W realizacji zastępuje roboczą nazwę Moi Klienci.
Nie jest to klasyczna lista wszystkich klientów ani ogólny CRM klientów.
Jest to kolejka spraw po podpisaniu umowy, które są aktualnie procesowane: przed montażem, w trakcie procesu, w trakcie montażu albo na późniejszym etapie realizacji.
Po przeniesieniu kontaktu do W realizacji aplikacja tworzy lub aktualizuje rekord sprawy realizacyjnej w osobnej tabeli, a kontakt znika z aktywnej listy Kontakty.
Część pól kontaktu i realizacji jest wspólna. Jeśli agent edytuje wspólne dane w jednej sekcji, na przykład adres albo numer telefonu, aplikacja automatycznie aktualizuje odpowiadające dane w drugiej sekcji.
Kontakt trafia do W realizacji dopiero po decyzji agenta. Nie dzieje się to automatycznie po samej zmianie statusu, ponieważ klient może się jeszcze rozmyślić.
Zakładka W realizacji powinna być zestawieniem spraw aktualnie procesowanych, z podstawowymi danymi klienta i informacjami potrzebnymi do realizacji umowy, tj. 
Imię i nazwisko 
Numer telefonu
Adres korespondencyjny
Adres montażu
Produkt
Typ klienta / forma płatności: gotówkowy albo na raty
Zakładka umowa
Data podpisania umowy
Numer umowy (opcjonalny)
Kwota netto
Kwota brutto
Prowizja agenta (wpisywana ręcznie)
Zakładka status realizacji
Status jest najważniejszym elementem formularza. Status ma być wybierany z listy rozwijanej. Powinna być na prawo od Zakładka umowa
Przykładowe statusy:
Podpisana umowa
Zgłoszone do ZE
Oczekiwanie na akceptację
Przed montażem
Montaż w toku
Po montażu
Zakończone
Wpisz własne
Status ma być widoczny i wyróżniony wizualnie. Wpisać można własny status. 
Statusy realizacji w W realizacji są osobną listą od statusów kontaktów.
Minimalne dane wymagane przy dodaniu do W realizacji to: dane kontaktu, adres i numer telefonu.
Domyślny status realizacji po dodaniu do W realizacji to Spisana umowa.
Domyślne etapy realizacji:
1. Spisana umowa
2. Po finansowaniu albo Wpłacona zaliczka
3. Po telefonie powitalnym
4. W trakcie umawiania montażu
5. W trakcie montażu
6. Zamontowany albo Po montażu
7. Zgłoszony do ZEI
8. Przyznana dotacja
Jeśli klient jest na raty, etap 2 nazywa się Finansowanie.
Jeśli klient jest gotówkowy, etap 2 nazywa się Wpłacona zaliczka.
W szczegółach sprawy W realizacji agent może zmienić typ klienta / formę płatności: gotówkowy albo na raty.
Statusy realizacji klientów są edytowalne przez agenta.
Zmiana statusu realizacji ma zmieniać kolor nagłówka klienta albo całej sekcji danych klienta, podobnie jak w aplikacji Thor CRM.
W podglądzie kafelka W realizacji nie pokazujemy produktu.
Agent ma widzieć aktualny etap realizacji oraz mieć wgląd w poprzednie etapy.
W szczegółach sprawy ma być widoczna historia zmian etapów/statusów wraz z dokładną datą i godziną zmiany.
Status Spad oznacza klienta, który po podpisaniu umowy i dodaniu do W realizacji rezygnuje. Taki klient nadal liczy się jako dodany klient, ale dodatkowo zasila statystykę spadów. Przy statusie Spad można dodać uwagę / notatkę do klienta.
Po ustawieniu statusu Spad aplikacja powinna pokazać przycisk Przenieś do archiwum.
Pozostałe statusy realizacji będą doprecyzowywane razem w dalszej pracy.
Zakładka realizacja 
Pole „Sposób realizacji”:
Gotówka
Finansowanie
Kwota netto i kwota brutto są wymagane przy danych umowy klienta.
Waluta to PLN.
Prowizja agenta jest ręcznym, opcjonalnym polem kwotowym.
Jeżeli wybrano „Finansowanie”, nie pokazuj dodatkowych pól, dodaj tylko możliwość dodania umowy kredytowej w 2 max załącznikach obok pola.
Daj max 5mb albo trzeba sprawdzić ile zajmuje 1 załącznik z banu
Jeżeli wybrano „Gotówka”, pokaż dodatkowe pole:
„Sposób płatności”
50/50
Etapami
Jeżeli wybrano 50/50 powinny się pojawić 2 pola do wpisania kwot. Pola można edytować (np. zamienić 30 na 50, a 50 na 70, ale łącznie ich suma powinna być równa 100)
Jeżeli wybrano „Etapami”, powinny się pojawić 3 pola do wpisania kwot. Procenty można zmieniać, a kwoty wpisać ręcznie.
Przykład:
20% → kwota wpłacona
30% → kwota wpłacona
50% → kwota wpłacona
Agent sam definiuje przedziały procentowe.
System musi pilnować, aby suma wszystkich etapów wynosiła dokładnie 100%.
Jeżeli suma nie wynosi 100%, formularz powinien wyświetlić błąd.
### Zakładka Dokumenty i zdjęcia
Celem tej funkcji jest umożliwienie agentowi terenowemu szybkiego dodania najważniejszych zdjęć lub dokumentów powiązanych z klientem, bez potrzeby korzystania z WhatsAppa, galerii telefonu lub zewnętrznych komunikatorów.
Najważniejsze założenie:Doorka nie ma być dyskiem Google ani biurowym CRM-em do przechowywania setek dokumentów. Funkcja dokumentów ma być maksymalnie prosta, lekka i terenowa.
Założenia funkcji:
dokumenty są przypisane wyłącznie do konkretnego klienta,
sekcja dokumentów znajduje się na dole karty klienta,
użytkownik może dodać maksymalnie 2 pliki o max 2mb łącznie, jeden dla skanu faktury, drugi dla umowy kredytowej klienta
aplikacja ma wspierać szybkie dodanie zdjęcia z telefonu lub aparatu, również w formie skan,
### Zakładka Notatki
Na ten moment w Moi Klienci nie zakładamy pola uwagi / notatki analogicznego do kontaktów.

## Model płatności aplikacji CRM
Model płatności, wersji darmowej i wersji Premium nie jest jeszcze ustalony.
Na ten moment nie rozgraniczaj funkcji na bezpłatne i płatne.
Projektuj aplikację jako jedną całość funkcjonalną, bez blokowania elementów za planem subskrypcyjnym.

## Ustawienia oraz preferencje użytkownika
Podziel ustawienia na następujące sekcje:
### 1. Profil 
Dodaj możliwość:
zmiany imienia i nazwiska,
zmiany numeru telefonu,
zmiany adresu e-mail,
dodania zdjęcia profilowego,
wpisania nazwy firmy lub zespołu,
wyboru branży sprzedażowej,
zmiany hasła,
wylogowania ze wszystkich urządzeń,
eksportu danych (statystyk),
usunięcia konta.
Usunięcie konta oraz wylogowanie ze wszystkich urządzeń wymagają dodatkowego potwierdzenia.
Usunięcie konta wymaga potwierdzenia przez e-mail.
Z perspektywy aplikacji konto znika od razu po usunięciu.
Technicznie w bazie danych konto może mieć 30 dni karencji, ale agent nie powinien widzieć tej informacji w aplikacji.
### 2. Praca i spotkania
Dodaj ustawienia:
domyślnych godzin rozpoczęcia spotkań,
dni pracy użytkownika,
początku tygodnia,
Domyślne godziny rozpoczęcia spotkań użytkownik powinien móc dodawać, usuwać i zmieniać ich kolejność.
### 3. Kontakty, statusy i produkty
Dodaj możliwość wyboru domyślnego statusu nowego kontaktu.
dodawać własne statusy,
zmieniać nazwy statusów,
zmieniać ich kolejność,
ukrywać nieużywane statusy,
przypisywać statusom kolory.
Nie pozwalaj usuwać statusu, jeśli jest przypisany do jakiegokolwiek kontaktu. Przed usunięciem użytkownik musi przenieść kontakty do innego statusu. Niech aplikacja się wtedy zapyta agenta czy na pewno chce to zrobić i jeśli chce to niech mu w tym pomoże pytając się go do jakiego statusu chce przenieść agentów. Nie można tego zrobić pojedynczo, tylko wszystkie statusy kopiujemy do innego statusu.
Dodaj ustawienia produktów. Użytkownik może:
włączać i wyłączać produkty widoczne w formularzu,
zmieniać kolejność produktów,
dodawać własne produkty,
Domyślna lista produktów:
PV + ME
ME
UPSELL
Dach
Pompa ciepła
Turbina Wiatrowa
Czyste Powietrze
Produkt nie jest zapisywany w oddzielnym polu bazy danych. Jest wykorzystywany do automatycznego tworzenia nagłówka w polu „Uwagi / notatki”.
### 4. Powiadomienia i przypomnienia
Dodaj osobne przełączniki dla:
przypomnienia o spotkaniach,
przypomnienia o telefonie do klienta,
przypomnienia o podjechaniu do klienta,
przypomnienie o kontakcie, u którego nie był zmieniany status od 3 dni (możliwość zmiany liczby dni)
kontaktów bez aktywności,
dziennego podsumowania pracy,
miesięcznego podsumowania wyników z informacją o progresie, bądź regresie w stosunku do poprzedniego miesiąca
tygodniowego podsumowania wyników,
Pozwól ustawić czas przypomnienia:
15 minut wcześniej,
30 minut wcześniej,
godzinę wcześniej,
dzień wcześniej,
własny czas.
Kanały powiadomień:
powiadomienie w aplikacji,
push,
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Agent może wybrać Przypomnij później za 15 minut, maksymalnie.
### 5. Dashboard
Dodaj możliwość zarządzania elementami widocznymi na Dashboardzie.
Dostępne elementy:
Rozpocznij leadowanie,
statystyka dnia,
porównanie aktualnego i poprzedniego tygodnia,
dzisiejsze spotkania,
ostatnio dodane kontakty,
kontakty wymagające działania dzisiaj,
liczba umówionych spotkań,
liczba odbytych spotkań,
konwersja.
Użytkownik może:
włączać i wyłączać elementy,
zmieniać ich kolejność,
ustawiać domyślny zakres statystyk: dzień, tydzień lub miesiąc.
Przy pierwszym uruchomieniu Dashboard powinien mieć gotowy, sensowny układ bez konieczności konfiguracji. Tz. domyślny
### 6. Funkcja „Rozpocznij leadowanie”
Dodaj ustawienia:
pokazywania funkcji na Dashboardzie,
zapisywania czasu leadowania w statystykach,
wyświetlania formularza podsumowania po zakończeniu,
ostrzeżenia, gdy licznik działa wyjątkowo długo,
pokazywania lub minimalizowania aktywnego licznika.
Po zatrzymaniu sesji użytkownik może zobaczyć:
czas leadowania,
liczbę dodanych kontaktów,
liczbę umówionych spotkań,
skuteczność sesji.
### 7. Wygląd aplikacji
Dodaj:
tryb jasny i tryb ciemny,
### 8. Raporty i podsumowania
Raport zawiera:
liczbę dodanych kontaktów,
liczbę umówionych spotkań,
liczbę podpisanych umów,
liczbę klientów dodanych do Moi Klienci,
liczbę spadów,
konwersję,
czas leadowania,
porównanie z poprzednim okresem.
Automatyczne raporty e-mailowe zostają w zakresie funkcjonalnym aplikacji, ale bez oznaczania ich jako funkcji premium.
Najważniejsze statystyki na start to: umówione spotkania, spisane umowy, klienci dodani do Moi Klienci oraz spady.
Spisana umowa liczy się w statystykach dopiero po dodaniu do Moi Klienci.
Tydzień w statystykach zaczyna się w poniedziałek.
Spad liczymy jako konwersję: (spisana umowa -> Moi Klienci) / status Spad i pokazujemy procentowo.
Czas leadowania, średni czas spotkania sprzedażowego oraz średni czas spotkania, gdzie klient jest zainteresowany, są pomysłami na późniejszy etap rozwoju aplikacji.
### 10. Bezpieczeństwo i prywatność
Dodaj:
logowanie dwuetapowe,
blokadę biometryczną,
automatyczną blokadę aplikacji,
wybór czasu blokady po bezczynności,
listę aktywnych urządzeń,
historię logowań,
wylogowanie ze wszystkich urządzeń,
pobranie kopii danych,
zarządzanie zgodami marketingowymi,
dostęp do polityki prywatności i regulaminu,
usunięcie konta.
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło. Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.
Reset hasła nie dotyczy użytkowników logujących się przez Google.
### 11. Dane i synchronizacja
Pokaż użytkownikowi:
status synchronizacji,
datę ostatniej synchronizacji,
informację, czy dane są bezpiecznie zapisane w chmurze.
Dodaj:
eksport kontaktów do CSV,
eksport raportów,
import kontaktów/moi klienci/statystyki z pliku,
automatyczną synchronizację.
Nie dodawaj użytkownikowi możliwości samodzielnego przywracania całej bazy danych z kopii zapasowej. Przywracanie danych powinno być wykonywane po stronie administratora lub systemu po odpowiedniej wiadomości e-mail.
W razie potrzeby kontakt z administratorem agent powinienem o tym zostać poinformowany na samym dole ustawień

## Powiadomienia
Aplikacja ma informować o:
wykonywanych telefonach,
kontaktach bez zmiany statusu od 3 dni,
terminie kontaktu z danym klientem,
## Offline i Online
Głównym źródłem danych aplikacji jest Supabase.com.
W Supabase trzymane są dane klientów, kontaktów, statusów, raportów i statystyk przypisanych do poszczególnych agentów.
Tryb offline jest wymaganiem docelowym, ale jego dokładny zakres techniczny nie jest jeszcze przesądzony. Na teraz zakładamy, że internet jest dostępny.
Założenie produktowe: jeśli agent straci internet, powinien móc dalej aktualizować dane klientów, kontaktów i statusów, a po odzyskaniu połączenia aplikacja ma automatycznie zsynchronizować zmiany z Supabase.
Aplikacja nie ma traktować lokalnej pamięci jako głównej bazy danych ani trzymać danych statycznie wyłącznie w aplikacji.
Lokalna pamięć może służyć jako cache oraz kolejka zmian wykonanych bez internetu.
Dodatkowo, przy offline agent powinien widzieć informacje zapisane poprzednio w online, jeśli są dostępne w lokalnym cache.
## Systemy aplikacji
Aplikacja powinna działać zarówno jak i na Android, tak i iOS
Na ten moment priorytetem jest aplikacja Flutter na iOS i Android.
Panel webowy app.doorka.pl nie jest aktualnym priorytetem i może zostać rozważony później.
