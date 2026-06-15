# CONVERSATION

Ten plik jest roboczym miejscem do prowadzenia projektu.
Ma byc aktualizowany na biezaco po decyzjach, pytaniach i zmianach w aplikacji.

## Zasady pracy

- Uzytkownik robi commity samodzielnie.
- Codex nie tworzy commitow i nie przygotowuje zmian do commita bez wyraznego polecenia.
- Dokumentacja w `/docs` jest zrodlem prawdy projektu.
- Jesli decyzja jest niepewna albo temat wraca pozniej, zapisujemy go w sekcji "Pozniej".
- Supabase ma teraz status "pit stop" i nie ruszamy zmian struktury bazy bez osobnej rozmowy.
- Ikony aplikacji zostaja na pozniejszy etap.

## Aktualny priorytet

Pierwszy priorytet to porzadek techniczny aplikacji i budowanie funkcji krok po kroku.
Na tym etapie nie probujemy zrobic wszystkiego naraz.

Najblizsze prace:

1. Porzadkowac kod aplikacji.
2. Wydzielac duze sekcje z `main.dart` do osobnych plikow.
3. Dopinac Dashboard jako glowne miejsce informacji o pracy agenta.
4. Zapisywac decyzje produktowe w dokumentacji.
5. Nie ruszac Supabase, dopoki nie wrocimy do rozmowy o tabelach.

## Porzadek techniczny kodu

### Co juz zrobiono

- Wydzielono wyglad aplikacji do `lib/app_design.dart`.
- Wydzielono modele danych do `lib/app_models.dart`.
- Dodano font Inter przez `google_fonts`.
- Ujednolicono czesc kolorow i wag tekstu w aplikacji.
- `main.dart` nadal jest duzy, ale pierwszy poziom porzadku jest wykonany.

### Co robimy dalej

Docelowo chcemy wydzielic sekcje aplikacji do osobnych plikow:

- Dashboard
- Kontakty
- W realizacji
- Statystyka
- Konto / ustawienia
- Wspolne komponenty UI
- Pomocnicze funkcje dat, telefonu, map i formatowania

To jest dobra praktyka, bo aplikacja bedzie latwiejsza do utrzymania.
Nie robimy jednak agresywnego refaktoru bez potrzeby.
Kazde wydzielenie powinno byc bezpieczne i sprawdzone przez `flutter analyze` oraz testy.

## Dashboard

Dashboard ma pokazywac rzeczy, dla ktorych aplikacja realnie powstaje.

### Trzy glowne skladowe aplikacji

Na dole Dashboardu ma byc kafelek porownawczy z trzema najwazniejszymi metrykami:

- ilosc umow przeprocesowanych,
- ilosc spotkan umowionych,
- ilosc czasu w terenie w formacie godziny, minuty i sekundy.

Domyslny okres porownania to tydzien.
Okres bedzie mozna pozniej wybrac w ustawieniach, ale na start przyjmujemy tydzien jako domyslny.

### Aktualne zalozenie

Kafelek "W tym tygodniu" na Dashboardzie ma byc oparty o:

- umowy / realizacje dodane w danym tygodniu,
- kontakty ze statusem `Umowione spotkanie` w danym tygodniu,
- sesje leadowania i ich `work_seconds`.

### Do pozniejszego dopracowania

- Dokladne znaczenie "umowa przeprocesowana".
- Czy liczymy tylko nowe realizacje, czy takze realizacje przesuniete etapami.
- Czy porownanie ma byc tydzien do tygodnia, miesiac do miesiaca albo zalezne od ustawien uzytkownika.
- Czy kafelek ma miec osobny widok szczegolowy po kliknieciu.

## Kontakty

### Decyzje

- Jeden agent nie moze miec dwoch kontaktow z tym samym numerem telefonu.
- Jesli agent probuje dodac kontakt z numerem, ktory juz istnieje u tego samego agenta, aplikacja ma pokazac komunikat i zablokowac dodanie kontaktu.
- Archiwum kontaktow ma byc dostepne w ustawieniach konta jako zakladka "Archiwum kontaktow".

### Do pozniejszego dopracowania

- Jak dokladnie odroznic "Szybki kontakt" od "Umowione spotkanie".
- Jak maja dzialac przypomnienia: po co, kiedy, dla kogo i w jakiej formie.
- Jak ma wygladac archiwum kontaktow i przywracanie kontaktu.

## W realizacji

### Decyzje

- "W realizacji" zostaje nazwa sekcji po klientach z podpisana umowa.
- Sekcja nie jest zwykla lista klientow, tylko miejscem sledzenia procesu realizacji.
- Szczegolowy kafelek realizacji jest waznym etapem, ale bedzie dopracowywany pozniej.

### Do pozniejszego dopracowania

- Szczegolowy widok realizacji.
- Historia zmian etapow.
- Dokladne daty przejscia przez etap.
- Czy "umowa przeprocesowana" na Dashboardzie ma byc liczona z tej sekcji.

## Statystyka

### Aktualne zalozenie

Statystyka ma wspierac Dashboard, ale nie musi od razu miec wszystkich zaawansowanych danych.
Najwazniejsze metryki na start:

- spotkania umowione,
- umowy / realizacje,
- czas leadowania,
- liczba sesji leadowania.

### Do pozniejszego dopracowania

- Konwersje.
- Spady.
- Jak liczyc skutecznosc agenta.
- Szczegoly statystyk po kliknieciu kafelka.

## Planowanie pracy

### Pomysl

Pojawia sie nowy pomysl na sekcje planowania miesiaca, tygodnia i dnia.
Agent moglby wpisywac planowane liczby w kalendarzu, np. liczbe umowionych spotkan i odbytych spotkan.
Funkcja moze pomagac w komunikacji z menadzerem: agent planuje miesiac w aplikacji i wysyla zrzut ekranu.

### Aktualny status

Temat planowania pracy zostaje odlozony.
Na teraz wazniejsza jest codzienna realizacja celu agenta w Dashboardzie.
Szczegoly zapisano w `docs/sections/Planning.md`.

### Do doprecyzowania

- Czy to bedzie osobna sekcja, czy czesc Dashboardu albo Statystyki.
- Czy agent wpisuje tylko liczby, czy tez notatki.
- Czy plan ma byc porownywany z wykonaniem.
- Czy manager docelowo ma widziec plan w aplikacji.

## Codzienna realizacja celu

### Najwazniejsza potrzeba

Agent powinien codziennie widziec w terenie, jaki ma cel na dzisiaj, np. 9 umowionych spotkan.
Aplikacja ma pomagac mu szybko dodawac spotkania, korygowac wynik i oznaczac sytuacje, ktore zmieniaja realizacje celu.

### Przyklady sytuacji

- Agent umawia spotkania w trakcie sesji leadowania.
- Agent konczy dzien, ale pozniej dzwoni albo odpisuje kontakt z kartki i chce dopisac spotkanie.
- Kontakt wysyla rano SMS, ze spotkanie jest odwolane.
- Agent musi szybko oznaczyc rezygnacje albo odwolanie spotkania.
- Wynik dnia powinien sie odpowiednio skorygowac.

### Aktualny kierunek

To powinno byc dostepne z Dashboardu albo aktywnego kafelka.
Agent nie powinien szukac tych funkcji gleboko w aplikacji.
Rozbudowane planowanie miesiaca i tygodnia zostaje pozniej.

## Konto i ustawienia

### Decyzje

- Ustawienia sa osobnym ekranem kategorii.
- Nie pokazujemy wszystkich opcji naraz na glownym ekranie ustawien.
- Archiwum kontaktow ma byc jedna z sekcji w ustawieniach.
- Archiwum kontaktow znajduje sie w kategorii Konto.
- Z archiwum agent moze przywrocic kontakt do aktywnej listy kontaktow.

### Do pozniejszego dopracowania

- Zapisywanie preferencji uzytkownika.
- Domyslny zakres porownania Dashboardu.
- Powiadomienia.
- Onboarding.
- Zdjecie profilowe w Supabase Storage.
- Zmiana hasla, wylogowanie i usuniecie konta jako pelny proces.

## Supabase

Status: pit stop.

Nie wykonujemy teraz zmian w strukturze bazy.
Do tematu wrocimy osobno, szczegolnie w kontekscie:

- tabel,
- statusow,
- czyszczenia starych danych,
- zgodnosci z dzialajaca aplikacja doorka.pl,
- danych niewyrzucalnych.

## Pozniej

- Ikony aplikacji dla iOS i Android.
- Finalny onboarding.
- Polityka prywatnosci i regulamin.
- Przypomnienia.
- Planowanie miesiaca, tygodnia i dnia.
- Pelne archiwum kontaktow.
- Pelny widok szczegolowy realizacji.
- Tryb ciemny / jasny i psychologia wyboru motywu.

## Otwarte pytania

- Jak dokladnie definiujemy "umowe przeprocesowana"?
- Czy Dashboard ma porownywac dane zawsze tydzien do tygodnia, czy wedlug ustawienia uzytkownika?
- Czy szybki kontakt ma miec osobny minimalny formularz, czy korzystac z tego samego procesu dodawania kontaktu?
- Jakie dane maja byc widoczne w archiwum kontaktow?
