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
- Zainteresowany
- Szybki kontakt
- Do podjechania
- Do przedzwonienia
- Niezainteresowany
- Brak kontaktu

Statusy domyślne mogą mieć własne zachowania i pola dodatkowe.

Nieusuwalne i nieedytowalne statusy kontaktów:
- Umówione spotkanie
- Zainteresowany
- Niezainteresowany
- Do podjechania

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

Aplikacja może wykrywać potencjalne duplikaty kontaktów po numerze telefonu.

## Status: Umówione spotkanie
Po wybraniu statusu Umówione spotkanie formularz pokazuje dodatkowe pola:
- data
- godzina
- produkt
- jakość

Data, godzina i produkt są obowiązkowe.
Jakość nie jest obowiązkowa.
Aplikacja domyślnie wybiera kolejny dzień jako datę spotkania.
Aplikacja domyślnie może ustawić godzinę 18:00.

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

## Status: Zainteresowany
Status Zainteresowany może mieć termin kontaktu.
Przypomnienia dotyczą między innymi kontaktów ze statusem Zainteresowany i terminem.

## Status: Do przedzwonienia
Status Do przedzwonienia zawiera dodatkową informację: termin kontaktu.
Termin kontaktu jest wybierany przez agenta ręcznie.
Agent może też dopisać własny termin.
Raz dopisany termin może zostać dostępny jako opcja do ponownego wyboru.

Termin kontaktu nie jest obowiązkowy.
Informacja o terminie może zostać zapisana w uwagach / notatkach.

Domyślne opcje terminu:
- Jutro
- za 2 dni
- w przyszłym tygodniu
- w przyszłym miesiącu
- konkretna data

## Status: Do podjechania
Status Do podjechania ma pole termin.
Termin może być wybierany kafelkami albo z kalendarza.
Dokładny sposób wyboru terminu zostanie dopracowany później.

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
