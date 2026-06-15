## Sekcje aplikacji
Szczegółowe opisy mechanizmów, funkcji i zachowań głównych sekcji znajdują się w folderze `docs/sections/`:
- Dashboard: `docs/sections/Dashboard.md`
- Kontakty: `docs/sections/Contacts.md`
- W realizacji: `docs/sections/In_process.md`
- Statystyka: `docs/sections/Statistics.md`
- Ustawienia: `docs/sections/Settings.md`

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

## Model płatności aplikacji CRM
Model płatności, wersji darmowej i wersji Premium nie jest jeszcze ustalony.
Na ten moment nie rozgraniczaj funkcji na bezpłatne i płatne.
Projektuj aplikację jako jedną całość funkcjonalną, bez blokowania elementów za planem subskrypcyjnym.

## Ustawienia oraz preferencje użytkownika
Szczegółowa organizacja ustawień znajduje się w `docs/sections/Settings.md`.

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
