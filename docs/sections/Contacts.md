# Contacts

Ten plik jest źródłem prawdy dla sekcji Kontakty.
Opisuje mechanizmy, funkcje i zachowania kontaktów przed przeniesieniem do W realizacji.
Wygląd kontaktów, kafelków i gestów opisują dodatkowo `docs/appereance/UX_UI.md` oraz `docs/appereance/design.md`.

## Rola sekcji
Kontakt jest głównym obiektem pracy agenta przed podpisaniem umowy i przeniesieniem do W realizacji.
Kontakt to osoba albo lead pozyskany przez agenta.

Agent może:
- dodać kontakt
- edytować kontakt
- zmienić status kontaktu
- dodać notatkę / uwagę
- zarchiwizować kontakt
- usunąć kontakt
- przenieść kontakt do W realizacji

## Podstawowe dane kontaktu
Podstawowe dane kontaktu:
- dane kontaktu
- adres
- numer telefonu
- status
- uwagi / notatki

Kontakt można zapisać bez numeru telefonu albo bez adresu, ale wtedy w polu uwagi / notatki musi znajdować się informacja pozwalająca agentowi rozpoznać klienta.

## Status kontaktu
Kontakt może mieć tylko jeden aktualny status.
Kontakty są dzielone głównie ze względu na status.

Domyślne statusy kontaktów:
- Umówione spotkanie
- Kontakt roboczy
- Do podjechania
- Niezainteresowany
- Brak kontaktu

Statusy domyślne mogą mieć własne zachowania i pola dodatkowe.

Nieusuwalne i nieedytowalne statusy kontaktów:
- Umówione spotkanie
- Niezainteresowany
- Do podjechania

## Etapy statusów kontaktu
Statusy kontaktu nie powinny być traktowane jako jedna płaska lista.
Status powinien wynikać z etapu życia kontaktu.

Główne etapy:
- w trakcie umawiania spotkania
- przed odbyciem spotkania
- w trakcie odbywania spotkania
- po odbytym spotkaniu
- po spisanej umowie

### W trakcie umawiania spotkania
To etap pracy w terenie i pozyskiwania leadów.
Statusy z tego etapu mogą zasilać licznik "Pozyskane leady".

Przykłady:
- Umówione spotkanie
- Kontakt roboczy
- Do podjechania

Umówione spotkanie jest zawsze liczone jako umówione spotkanie oraz jako część pozyskanych leadów.

### Kontakt roboczy
Kontakt roboczy to robocza nazwa dla kontaktu, który agent zapisuje, ale który nie jest liczony do statystyk i pozyskanych leadów.
Przykład: żona otwiera drzwi i podaje numer telefonu do męża, żeby agent zadzwonił później.
To nie jest jeszcze pozyskany lead, ponieważ osoba decyzyjna może później powiedzieć, że nie jest zainteresowana.

Kontakt roboczy ma pomagać agentowi nie zapomnieć o sprawie.
Nie powinien być traktowany jako wynik pracy w leadowaniu.
Kontakt roboczy musi mieć przynajmniej numer telefonu albo adres.
Sam telefon wystarczy.
Jeśli agent chce zapisać tylko luźny tekst bez telefonu i bez adresu, używa Szybkiej notatki, a nie Kontaktu roboczego.

Kontakt roboczy może później zostać:
- zamieniony na Umówione spotkanie
- zamieniony na Do podjechania
- wysłany do archiwum

Dopiero po zamianie na Umówione spotkanie albo Do podjechania kontakt zaczyna wpływać na liczniki.

### Przed odbyciem spotkania
To etap po umówieniu spotkania, ale przed wizytą u klienta.
Kontakt ma już termin spotkania i jest częścią dnia sprzedażowego.

Możliwe statusy albo oznaczenia:
- Umówione spotkanie
- Przełożone
- Do potwierdzenia

Odwołane spotkanie nie jest normalnym statusem widocznym na liście statusów.
Jest szybką akcją albo oznaczeniem przy umówionym spotkaniu.
Po oznaczeniu spotkania jako odwołane aplikacja koryguje wynik netto i może później przenieść taki kontakt do archiwum po akceptacji agenta.

Przełożone jest stanem przed ponownym Umówionym spotkaniem.
Kontakt w stanie Przełożone nie liczy się do aktywnego wyniku.
Ten sam kontakt nie może zdublować wyniku przez samo przełożenie terminu.
Po ustawieniu nowego terminu kontakt wraca do stanu Umówione spotkanie, ale nie tworzy drugiego wyniku za ten sam kontakt.

### W trakcie odbywania spotkania
To etap dnia sprzedażowego.
Statusy z tego etapu mogą służyć aktywnemu kafelkowi spotkania.

Przykłady:
- W trakcie spotkania
- Spotkanie odbyte
- Nie wszedłem

Etap W trakcie spotkania zaczyna się dopiero po akcji agenta, np. kliknięciu "Start spotkania" albo "Wszedłem".
Samo nadejście godziny spotkania nie rozpoczyna tego etapu automatycznie.

### Po odbytym spotkaniu
To etap po zakończeniu rozmowy sprzedażowej.
Status zależy od końcówki spotkania.

Przykłady:
- Spisana umowa
- Niezainteresowany
- Zainteresowany z terminem kontaktu

Niezainteresowany jest statusem po odbytym spotkaniu.
Nie powinien być liczony jako pozyskany lead z dnia umawiania spotkań.

### Po spisanej umowie
Po spisaniu umowy kontakt może zostać przeniesiony do W realizacji.
Od tego momentu zaczyna się proces realizacji, a nie zwykła obsługa kontaktu.

## Zmiana statusu
Zmiana statusu nie zapisuje się automatycznie po samym kliknięciu.
Proces zmiany statusu:
1. Użytkownik klika aktualny status.
2. Wybiera nowy status z listy.
3. System pokazuje podsumowanie zmiany.
4. Użytkownik musi kliknąć "Zatwierdź".
5. Dopiero po zatwierdzeniu nowy status zostaje zapisany.

Po zatwierdzeniu można przez kilka sekund pokazać opcję "Cofnij".

## Aktywność kontaktu
Aktywność nie jest osobnym zadaniem ani statusem.
Aktywność jest automatycznie tworzoną historią tego, co działo się z kontaktem w czasie.

Aktywność zapisuje historię zmian statusów kontaktu.
W aplikacji aktywność ma zapamiętywać historię zmian.
W Supabase dla kontaktu ma być zapisany obecny status kontaktu.

## Dodawanie kontaktu
Formularz dodawania kontaktu zawiera podstawowe pola:
- dane kontaktu
- adres
- numer telefonu
- status
- uwagi / notatki

Aplikacja blokuje duplikaty kontaktów po numerze telefonu dla tego samego agenta.
Jeśli agent próbuje dodać kontakt z numerem telefonu, który już istnieje na jego aktywnej liście kontaktów, aplikacja pokazuje komunikat i uniemożliwia dodanie kontaktu.
Porównanie numeru telefonu powinno ignorować spacje, myślniki i nawiasy.
Duplikaty między różnymi agentami nie są blokowane na tym etapie.

W trybie leadowania agent nie powinien ręcznie wybierać statusu z listy.
Status powinien wynikać z przycisku, którego użyje agent.
Przykłady:
- przycisk Umów spotkanie tworzy kontakt ze statusem Umówione spotkanie
- przycisk Do podjechania tworzy kontakt ze statusem Do podjechania
- przycisk Kontakt roboczy tworzy kontakt roboczy, który nie liczy się do statystyk

## Status: Umówione spotkanie
Po wybraniu statusu Umówione spotkanie formularz pokazuje dodatkowe pola:
- data
- godzina
- produkt
- jakość

Minimalne dane dla Umówionego spotkania:
- imię albo dane kontaktu
- adres
- dzień spotkania
- produkt

Numer telefonu nie zawsze jest obowiązkowy.
Adres jest obowiązkowy.
Dzień spotkania jest obowiązkowy.
Godzina spotkania jest domyślnie ustawiana na 18:00.
Produkt jest obowiązkowy.
Jakość nie jest obowiązkowa.
Aplikacja domyślnie wybiera kolejny dzień jako datę spotkania.
Aplikacja domyślnie może ustawić godzinę 18:00.

Produkt powinien być wybierany z listy.
Domyślny produkt to PV + ME.

Dzień spotkania oznacza dzień odbycia spotkania.
Nie pokazujemy agentowi osobno daty, kiedy spotkanie zostało umówione, jeśli nie jest to potrzebne w interfejsie.

Produkt jest wykorzystywany do automatycznego tworzenia nagłówka w polu "Uwagi / notatki".
Produkt nie musi być oddzielnym polem bazy danych dla kontaktu, jeśli pełna informacja zostaje zapisana w notatce.

Domyślna lista produktów:
- PV + ME
- ME
- UPSELL
- Dach
- Pompa ciepła
- Turbina Wiatrowa
- Czyste Powietrze

Lista jakości:
- S
- M
- L
- XL

Po wybraniu dnia, godziny, produktu oraz jakości system automatycznie tworzy nagłówek i umieszcza go na początku pola "Uwagi / notatki".
Format:
`09.06 (wt.), 12:00 | PV + ME | XL |`

Agent może dopisać własną treść bezpośrednio po automatycznym nagłówku.
Wszystkie wybrane informacje mają być widoczne w polu "Uwagi / notatki".
Pole "Uwagi / notatki" można ręcznie edytować w dowolnym momencie.

## Status: Do podjechania
Status Do podjechania ma pole termin.
Do podjechania oznacza sytuację, w której klient mówi agentowi, żeby podjechać w przyszłości, np. za 3 miesiące.
Kontakt Do podjechania powinien być normalnym statusem widocznym na liście.
Liczy się jako pozyskany lead od razu po zapisaniu.
Nie liczy się jako umówione spotkanie.
Do podjechania musi mieć przynajmniej imię albo dane kontaktu, adres oraz ogólny termin.

Kontakt Do podjechania może później zmienić się w:
- Umówione spotkanie
- Niezainteresowany / archiwum
- Do podjechania dalej, jeśli termin się przesuwa albo coś klientowi wypadło

Do podjechania musi mieć termin albo przedział czasu, żeby aplikacja wiedziała, kiedy przypomnieć agentowi o kontakcie.
Podstawowe kafelki terminu:
- za tydzień
- za miesiąc
- za 3 miesiące
- własny termin

Gdy nadejdzie termin, aplikacja przypomina agentowi, że teraz jest czas podjechać do tego kontaktu.
Agent wybiera wtedy:
- Podjeżdżam
- Do archiwum / nieaktualne

## Status: Do przedzwonienia
Do przedzwonienia działa podobnie jak Do podjechania w zakresie terminu.
Kontakt musi mieć ogólny termin, żeby aplikacja wiedziała, kiedy przypomnieć agentowi o telefonie.
Podstawowe kafelki terminu są takie same:
- za tydzień
- za miesiąc
- za 3 miesiące
- własny termin

Do przedzwonienia nie liczy się jako umówione spotkanie.
O tym, czy liczy się jako lead, decyduje późniejsza zamiana na Umówione spotkanie albo Do podjechania.

## Szybka notatka
Szybka notatka to wyłącznie luźny tekst agenta.
Może nie mieć telefonu, adresu ani danych kontaktu.
Nie liczy się jako lead i nie liczy się jako umówione spotkanie.
Szybkiej notatki nie zamieniamy na kontakt.
Można ją tylko usunąć.
Tym różni się od Kontaktu roboczego.

## Status: Niezainteresowany
Po wybraniu statusu Niezainteresowany aplikacja może pokazać czerwony przycisk przeniesienia kontaktu do archiwum.
Kontakt powinien zostać usunięty z aktywnej listy Kontakty.

## Archiwum i usuwanie
Przesunięcie kontaktu w lewo odsłania akcje:
- Archiwum
- Usuń

Sama czynność przesunięcia nie usuwa kontaktu.
Każda z tych akcji wymaga potwierdzenia komunikatem, że akcji nie można odwrócić.

Przy trwałym usuwaniu aplikacja pokazuje popup potwierdzający.
Nie wymagamy wpisywania słowa USUŃ.

Kontakt z archiwum można przywrócić do aktywnych kontaktów.

Archiwum kontaktów ma być dostępne w ustawieniach konta jako osobna zakładka "Archiwum kontaktów".

## Przeniesienie do W realizacji
Kontakt trafia do W realizacji dopiero po decyzji agenta.
Nie dzieje się to automatycznie po samej zmianie statusu, ponieważ klient może się jeszcze rozmyślić.

Dodanie do W realizacji odbywa się przez przesunięcie kafelka kontaktu w prawo.
Po przeniesieniu kontakt znika z aktywnej listy Kontakty.

Minimalne dane wymagane przy przeniesieniu do W realizacji:
- dane kontaktu
- adres
- numer telefonu

## Nawigacja i telefon
Przy adresie klienta albo kontaktu aplikacja ma mieć przycisk otwarcia zewnętrznej mapy.
Agent może dzięki temu uruchomić nawigację bez ręcznego wpisywania adresu.

Po kliknięciu przycisku telefonu aplikacja korzysta z funkcji dzwonienia w telefonie.

## Powiązania z innymi sekcjami
Kontakty zasilają:
- Dashboard
- W realizacji
- Statystykę

Kontakt po przeniesieniu do W realizacji przestaje być aktywnym kontaktem na liście Kontakty.
