# Bezpieczeństwo danych
Kontakty / Moi klienci są przypisane BEZPOŚREDNIO DO AGENTA. Żaden inny agent nie ma prawa widzieć czyichś kontaktów / statystyk i innych informacji.

Zabezpieczone jest to za pomocą RLS w Supabase

## Źródło prawdy projektu
Pliki Markdown w folderze `/docs` są głównym źródłem prawdy dla aplikacji tworzonej w tym projekcie.
Obecna aplikacja Flutter ma być budowana na podstawie decyzji, procesów i założeń zapisanych w tych plikach.
Istniejący lokalny projekt `/Users/kacstelmach/crm` oraz działająca aplikacja na doorka.pl są traktowane jako techniczna referencja i źródło istniejącej logiki, ale nie nadpisują aktualnych decyzji zapisanych w `/docs`.
Jeśli kod z `/crm` różni się od dokumentacji, pierwszeństwo ma dokumentacja, a różnica powinna zostać zapisana jako pytanie, ryzyko albo decyzja do potwierdzenia.

## Domena / hosting / kod i pliki / bazy danych aplikacji
https://doorka.pl - obecnie działa tam aplikacja Doorka.
Ten fakt zmienia kolejność prac: przed tworzeniem nowych migracji lub struktur trzeba najpierw sprawdzić istniejącą aplikację, istniejący projekt Supabase oraz obecne dane.

app.doorka.pl - subdomena aplikacji CRM

Aplikacja na dzień dzisiejszy (15.06) działa w wersji web app na doorka.pl, natomiast docelowo będzie ona zaprojektowana pod aplikację działającą online oraz z możliwością pracy bez internetu w zakresie cache i synchronizacji zmian.

Baza danych aplikacji jest podpięta pod Supabase.com, domena w lh.pl, hosting w vercel.com, a pliki i kod dostępna w https://github.com/kcprstlmch/doorka
Supabase jest głównym źródłem danych dla klientów, kontaktów, statusów, raportów i statystyk agentów. Dane lokalne w aplikacji, jeśli będą używane, mają pełnić rolę cache oraz kolejki zmian do synchronizacji.
Nowa aplikacja Flutter ma od początku łączyć się z tą samą bazą Supabase, z której korzysta doorka.pl.
Docelowo baza doorka.pl ma zostać uporządkowana i zaktualizowana do statusów oraz danych opisanych w dokumentacji `/docs`.
W bazie istnieją już dane, których nie wolno usuwać bez świadomej decyzji.
Większość danych testowych oraz kont agentów innych niż konto właściciela prawdopodobnie będzie do usunięcia, ale wymaga to osobnego przeglądu przed czyszczeniem.

## Użytkownik - agent
Aplikacja jest dla agenta sprzedaży bezpośredniej. Pracuje w terenie, sam buduje bazę kontaktów poprzez leadowanie, czyli dzień, w którym pozyskuje kontakty (umawianie spotkań)
Dwa tryby dnia agenta: leadowy i sprzedażowy
W dzień leadowy umawia spotkania (zdobywa nowe kontakty oraz jeżeli jest umówione to zmienia status na Umówione spotkanie), a w dzień sprzedażowy je odbywa (zmiana statusu na niezainteresowany, spisana umowa, do przedzwonienia)

Domyślna rola agenta to agent.
Obecnie aplikacja jest projektowana dla pojedynczych agentów. Panel firmowy, managerski albo widok wielu agentów nie jest aktualnym zakresem prac.
Agent może samodzielnie utworzyć konto w aplikacji.

## Kontakt
Ktoś kogo agent pozyskał. Kontakt można dodać, usunąć, dodać do zakładki moi klienci oraz dodać do archiwum, można mu również zmienić status.
Status jest najbardziej podstawową określająca “wartość” danego kontaktu dla agenta.
Archiwum to miejsce tz. śmietnik. Wrzucamy tam klientów. Archiwum można w pewnym momencie wyczyścić i usunąć permanentnie.
Po dodaniu kontaktu do sekcji Moi Klienci kontakt automatycznie znika z listy kontaktów.

Każdy kontakt jest indywidualnie przypisany do danego agenta.
Agent nie może widzieć czyichś kontaktów ani statystyk i nic innego, poza swoimi danymi
## Moi Klienci
To są kontakty, którym został zmieniony status na spisana umowa i zostali przeniesieni do zakładki Moi Klienci.
Moi Klienci to osobna sekcja aplikacji i osobna tabela w bazie danych, a nie tylko inny widok tej samej listy kontaktów.

## Statystyka w sprzedaży bezpośredniej
Praca w sprzedaży bezpośredniej w głównej mierze opiera się na statystyce. Standardową statystyką panującą w sprzedaży bezpośredniej w branży OZE jest 9/4/1. 9 umówionych, 4 odbyte i 1 spisana umowa. 

Dlatego tak ważny elementem w aplikacji jest sekcja Statystyka, ponieważ ona określa wartość agenta, jego skuteczność oraz efektywność w pracy. Czym większy procent przy liczbie tym większa skuteczność klienta. Czym większa skuteczność, tym większa prowizja wypłacona przez firmę, w której agent pracuje.
