# Procesy użytkownika

Ten plik opisuje najważniejsze procesy pracy agenta w aplikacji.

## Założenia
Na teraz nie opisujemy osobno dnia leadowego i dnia sprzedażowego jako osobnych procesów, ponieważ ich finalny kształt nie jest jeszcze przesądzony.
Proces dodawania kontaktu będzie najprawdopodobniej dostępny głównie przez Przycisk Szybkiej Akcji.
Istniejąca aplikacja webowa w `/Users/kacstelmach/crm` jest używana jako techniczna referencja dla działających procesów, ale nowe procesy Fluttera muszą być zgodne z aktualną dokumentacją.

## Przycisk Szybkiej Akcji
Przycisk Szybkiej Akcji służy do szybkiego wykonania najważniejszych działań w terenie.

Aktualnie zakładane akcje:
- Umów spotkanie
- Szybki kontakt
- Szybka notatka

Kolejne akcje będą omawiane na dalszych etapach rozwoju aplikacji.

## Umów spotkanie
Agent wybiera akcję Umów spotkanie z Przycisku Szybkiej Akcji.
Aplikacja pokazuje formularz kontaktu ze statusem Umówione spotkanie.
Agent uzupełnia dane klienta, adres, numer telefonu, datę, godzinę, produkt oraz uwagi.
Data, godzina i produkt są obowiązkowe.
Jakość nie jest obowiązkowa.
Aplikacja domyślnie wybiera kolejny dzień jako datę spotkania.
Aplikacja domyślnie może ustawić godzinę 18:00.
Docelowo lista godzin spotkań ma być pobierana z ustawień agenta dotyczących standardowych godzin umawiania spotkań.
Po zapisaniu kontakt trafia do listy Kontakty i może pojawiać się w Dashboardzie jako umówione spotkanie.

## Szybki kontakt
Agent wybiera akcję Szybki kontakt z Przycisku Szybkiej Akcji.
Aplikacja pokazuje uproszczony formularz z podstawowymi danymi.
Szybki kontakt służy do zapisania minimalnych informacji w presji czasu.
Pola szybkiego kontaktu to dane kontaktu oraz uwagi / notatki.
Szybki kontakt automatycznie ustawia status Szybki kontakt.

## Szybka notatka
Agent wybiera akcję Szybka notatka z Przycisku Szybkiej Akcji.
Dokładny zakres tej funkcji wymaga doprecyzowania.
Na ten moment szybka notatka jest planowaną akcją na późniejszy etap.
Prawdopodobnie będzie to informacja, którą później można przypisać do kontaktu, terenu albo nagrania.

## Zmiana statusu
Agent otwiera kartę kontaktu albo klienta.
Agent klika aktualny status.
Aplikacja pokazuje listę dostępnych statusów.
Agent wybiera nowy status.
Aplikacja pokazuje podsumowanie zmiany: poprzedni status i nowy status.
Agent zatwierdza zmianę przyciskiem Zatwierdź.
Dopiero po zatwierdzeniu nowy status zostaje zapisany.
Zmiana statusu zapisuje się w aktywności.
Aktywność obejmuje historię zmian statusów, a nie każdą edycję danych.

## Przeniesienie kontaktu do Moi Klienci
Kontakt nie trafia automatycznie do Moi Klienci po samej zmianie statusu.
Agent decyduje, czy kontakt może stać się klientem.
Po kliknięciu przycisku Dodaj do Moi Klienci aplikacja tworzy albo aktualizuje rekord w osobnej tabeli klientów.
Kontakt znika z aktywnej listy Kontakty.
Wspólne dane kontaktu i klienta, na przykład adres albo numer telefonu, pozostają zsynchronizowane.
Minimalne dane wymagane przy przeniesieniu do Moi Klienci to dane kontaktu, adres i numer telefonu.
Klient może docelowo wrócić do kontaktów, jeśli się rozmyśli, ale dokładny proces wymaga doprecyzowania.
W istniejącej aplikacji webowej kontakt może tworzyć rekord w `crm_leads` z oznaczeniem źródła kontaktu.
W Flutterze ten proces trzeba przemodelować pod aktualną zasadę: Moi Klienci są osobną sekcją i osobną strukturą danych, a nie tylko statusem kontaktu.

## Spad klienta
Jeśli klient po podpisaniu umowy i dodaniu do Moi Klienci rezygnuje, agent może oznaczyć go statusem Spad.
Taki klient nadal liczy się jako dodany klient, ale dodatkowo zasila statystykę spadów.
Przy oznaczeniu statusu Spad agent może dodać uwagę / notatkę do klienta.
Po ustawieniu statusu Spad aplikacja pokazuje przycisk Przenieś do archiwum.

## Dzwonienie
Kliknięcie numeru telefonu ma korzystać z funkcji dzwonienia w telefonie.
Aplikacja nie pokazuje po zakończeniu połączenia pytania o zmianę statusu ani notatkę.

## Mapy
Przy adresie klienta albo kontaktu aplikacja ma mieć przycisk otwarcia zewnętrznej mapy.
Agent może dzięki temu uruchomić nawigację bez ręcznego wpisywania adresu.

## Sesja leadowania
Rozpocznij leadowanie uruchamia licznik czasu.
Agent może pauzować sesję, na przykład na przerwę obiadową.
Cel sesji obejmuje liczbę umówionych spotkań oraz liczbę zebranych kontaktów.
Po zakończeniu sesji ma pojawić się podsumowanie.
Funkcja Zamknij dzień pojawia się wtedy, gdy agent zrealizuje cel danego spotkania/sesji leadowania.

## Archiwizacja kontaktu
Agent może przenieść kontakt do archiwum.
Przed archiwizacją aplikacja pokazuje popup z pytaniem, czy agent na pewno chce przenieść kontakt do archiwum.
Po potwierdzeniu kontakt znika z aktywnej listy kontaktów i trafia do archiwum.

## Usuwanie permanentne z archiwum
Agent może usuwać dane permanentnie z archiwum.
Przed trwałym usunięciem aplikacja pokazuje ostrzeżenie, że danych nie będzie można przywrócić.
Agent może zaznaczyć, które kontakty chce usunąć permanentnie, a które zostawić w archiwum.

## Archiwum klientów
Archiwum klientów działa podobnie jak archiwum kontaktów.
Trwałe usunięcie klienta wymaga potwierdzenia i komunikatu, że danych nie będzie można przywrócić.
Trwałe usuwanie jest możliwe tylko z archiwum.
Potwierdzenie trwałego usunięcia odbywa się przez popup, bez wpisywania słowa USUŃ.

## Usunięcie konta
Agent może sam usunąć konto po potwierdzeniu przez e-mail.
Z perspektywy aplikacji konto znika od razu.
Technicznie konto może mieć 30 dni karencji w bazie danych, ale agent nie powinien widzieć tej informacji w aplikacji.

## Reset hasła
Na ekranie logowania ma być opcja Nie pamiętasz hasła?.
Reset hasła dotyczy kont zakładanych przez e-mail i hasło.
Agent wpisuje swój e-mail, a system wysyła wiadomość z resetem hasła.
Reset hasła nie dotyczy użytkowników logujących się przez Google.

## Przypomnienia
Spotkanie nie tworzy domyślnie przypomnienia.
Przypomnienia dotyczą kontaktów z terminem przyjechania albo statusem Zainteresowany z terminem.
Przypomnienie pojawia się o konkretnym terminie i godzinie.
Nie ma wcześniejszego przypomnienia. Agent może wybrać Przypomnij później za 15 minut, maksymalnie.

## Statystyki
Statystyki są pobierane i wyliczane automatycznie na podstawie danych agenta zapisanych w Supabase.
Agent nie wpisuje statystyk ręcznie.
Najważniejsze statystyki na start to umówione spotkania, spisane umowy, klienci dodani do Moi Klienci oraz spady.
Spisana umowa liczy się w statystykach dopiero po dodaniu do Moi Klienci.
Tydzień w statystykach zaczyna się w poniedziałek.
Spad liczymy jako konwersję: (spisana umowa -> Moi Klienci) / status Spad i pokazujemy procentowo.
