# Ustawienia

Ten plik jest źródłem prawdy dla organizacji ekranu Konto / Ustawienia / Preferencje w aplikacji.

## Zasada główna
Ustawienia są otwierane z avatara albo inicjałów agenta w prawym górnym rogu topbara.
Panel ustawień wysuwa się z prawej strony i przykrywa cały ekran aplikacji.
W panelu ustawień na górze po prawej stronie jest przycisk `X`, który zamyka ustawienia.

Ekran główny ustawień pokazuje profil agenta oraz krótką listę kategorii.
Po kliknięciu kategorii użytkownik przechodzi do osobnego ekranu szczegółów tej kategorii.
Na ekranie szczegółów widzi dopiero konkretne ustawienia.

## Główny ekran ustawień
Na górze ekranu widoczny jest profil agenta:
- imię / nazwa użytkownika
- adres e-mail
- inicjały albo zdjęcie profilowe

Główny ekran ustawień pokazuje tylko następujące elementy:
- Konto
- System pracy - leadowanie
- Sprzedaż
- Kontakty
- Archiwum
- Wersja aplikacji: 0.0.1

Nie pokazujemy teraz sekcji:
- Dashboard
- Raporty
- Wygląd aplikacji
- Pomoc i informacje
- Mechanika 1.2

Powiadomienia nie są kategorią ustawień.
Są osobną ikoną w topbarze obok konta.

## 1. Konto
Sekcja Konto zawiera:
- Imię i nazwisko
- Adres e-mail
- Numer telefonu
- Numer agenta
- Wyloguj

Na obecnym etapie nie pokazujemy w tej sekcji:
- nieprzerobionych spotkań
- zmiany hasła
- usuwania konta
- branży sprzedażowej

## 2. System pracy - leadowanie
Sekcja System pracy - leadowanie zawiera:
- Ilość cykli: do wyboru 2 albo 3
- Il. um. spotkań - cel
- Pokazywać cel tygodniowy? przełącznik tak / nie

Cel umówionych spotkań jest domyślnie ustawiany jako liczba spotkań.
Ustawienie celu ma wpływać na statystyki tygodniowe i sposób pokazywania postępu agenta.

## 3. Sprzedaż
Sekcja Sprzedaż zawiera wybór produktów, które agent może mieć aktywne w aplikacji:
- Panele
- Magazyny
- Dachy
- Zestawy
- Ocieplenia
- Ogrzewanie
- Turbiny wiatrowe

Produkty są wybierane przełącznikami.
Na obecnym etapie produkty są preferencją użytkownika w ustawieniach, a nie obowiązkowym polem podczas dodawania spotkania.

## 4. Kontakty
Sekcja Kontakty pozwala agentowi zarządzać typami kontaktów, statusami roboczymi i szablonami SMS.

Agent może:
- dodać typ kontaktu,
- edytować nazwę typu,
- usunąć własny typ,
- dodać status,
- edytować nazwę statusu,
- usunąć własny status,
- dodać szablon SMS,
- edytować szablon SMS,
- usunąć szablon SMS.

Kolory typów i statusów nadaje automatycznie system.
Agent wpisuje tylko nazwę typu albo statusu.
Przy edycji nazwy kolor zostaje taki sam, żeby oznaczenia w kontaktach nie zmieniały się przypadkiem.

Kontakt domyślnie może nie mieć statusu roboczego.
Brak statusu jest zapisywany w SQL jako `NULL`.
Statusy agent dodaje w tej sekcji ustawień.
Statusy systemowe pozostają bazą mechaniki aplikacji i nie są edytowane przez agenta.
Statusy własne są warstwą roboczą agenta.
Etap decyduje, gdzie rekord jest w aplikacji, a status własny opisuje sytuację roboczą w tym etapie.

Systemowa paleta typów i statusów ma maksymalnie 10 kolorów.

Typy kontaktów są używane tylko w sekcji Kontakty.
Typ kontaktu nie jest pokazywany w sekcji Umówione spotkania.

### Szablony SMS

Szablony SMS są częścią sekcji Kontakty, bo SMS jest formą kontaktu z klientem.

Agent może tworzyć własne szablony, np.:
- `Spóźnię się`,
- `Nie przyjadę`,
- `Oddzwonię`.

Szablon SMS ma:
- nazwę szablonu,
- treść wiadomości.

Po wybraniu szablonu aplikacja nie wysyła SMS automatycznie.
Otwiera systemową aplikację SMS z wpisanym numerem klienta i treścią wiadomości.
Agent sam klika `Wyślij` w telefonie.

W tej sekcji ma być też przełącznik globalny:
- `Dopisuj podpis do SMS`

Tekst podpisu agenta zostaje do doprecyzowania później.
Zmienne w szablonach SMS zostają odłożone na później.

## 5. Archiwum
Sekcja Archiwum w Ustawieniach ma gromadzić elementy, które nie zostały domknięte w zakończonym cyklu pracy.

Po zakończeniu cyklu, np. następnego dnia, aplikacja powinna przenieść do archiwum wszystko, co nie zostało oznaczone wynikiem albo decyzją agenta.

Do archiwum cyklu trafiają między innymi:
- umówione spotkania bez wyniku,
- kontakty bez dalszej decyzji,
- inne rekordy pozostawione bez oznaczenia w trakcie cyklu.

Archiwum nie jest główną sekcją pracy.
Jest miejscem porządkowym w Ustawieniach, żeby aktywne ekrany nie były zaśmiecone starymi, niedomkniętymi rekordami.

## Zapamiętane spotkania
W Ustawieniach powinna istnieć sekcja Zapamiętane spotkania.
To miejsce przechowuje zakończone spotkania, które mają wartość informacyjną dla agenta, ale nie są już aktywną pracą.

W Zapamiętanych spotkaniach zapisujemy szczegóły takie jak:
- dane kontaktu,
- data spotkania,
- typy kontaktu,
- wynik spotkania,
- powód braku sprzedaży,
- wnioski na przyszłość,
- notatki agenta.

Zapamiętane spotkania służą uczeniu się z rozmów i porządkowaniu historii.
Nie jest tym samym co usunięcie kontaktu.
Z zapamiętanego spotkania agent może przywrócić kontakt, jeśli klient wróci albo zmieni zdanie.

## Wersja aplikacji
Aktualna wersja aplikacji widoczna w ustawieniach: `0.0.1`.

Wersja aplikacji jest elementem informacyjnym.
Nie otwiera osobnego ekranu szczegółów.

## UX/UI ustawień
Wygląd ekranu ustawień, kafelków kategorii, avatara, przycisku `X` i przejść opisuje `docs/appereance/UX_UI.md`.
