# BuildIT

Seminarski rad iz predmeta Razvoj softvera II

## Upute za pokretanje

Nakon kloniranja repozitorija uraditi sljedeće:

- **Extractovati:** `env`
- **Postaviti `.env` fajl u:** `\BuildIT\BuildIT`
- **Otvoriti `\BuildIT\BuildIT` u terminalu i pokrenuti komandu:**

Prije korištenja aplikacije pročitati napomene koje se mogu pronaći u ovom readme-u:

- **Extractovati:** `fit-build-2025-12-08-desktop`
- **Pokrenuti** `BuildIT_desktop.exe` koji se nalazi u folderu "Release"
- **Unijeti desktop kredencijale** koji se mogu pronaći u ovom readme-u

- Prije pokretanja mobilne aplikacije pobrinuti se da aplikacija već ne postoji na Android emulatoru; ukoliko postoji, uraditi deinstalaciju iste
- **Extractovati:** `fit-build-2025-12-08-mobile`
- Nakon extractovanja, prevući `.apk` fajl koji se nalazi u folderu "flutter-apk" i sačekati da se aplikacija instalira
- Nakon što je aplikacija instalirana, pokrenuti je i unijeti mobilne kredencijale koji se mogu pronaći u ovom readme-u

## Korištenje aplikacije

- Potrebno je prvo napraviti artikal, pa nakon toga oglas
- Prilikom prvog pokretanja se seeda data za 2 usera i 1 admina, kao i 2 grada (Sarajevo i Mostar)

## Kredencijali

### Desktop aplikacija

#### Administrator

- **Korisničko ime:** `admin`
- **Lozinka:** `test`

### Mobilna aplikacija

#### Korisnik

- **Korisničko ime:** `user1`
- **Lozinka:** `test`

- **Korisničko ime:** `user2`
- **Lozinka:** `test`

### Stripe

- **Broj kartice:** `4242 4242 4242 4242`
- **Datum isteka:** `12/34` (proizvoljno)
- **CVC:** `123` (proizvoljno)

## RabbitMQ

- **RabbitMQ** je korišten za slanje mailova prodavcima za obavještenja o njihovim kupljenim artiklima.
- Također se u slučaju primitka novih poruka u chatu.

## Color-coded calendar

- Ako je oglas postavljen kao iznajmljivanje, onda korisnik ima pristup pregledu dana kada je artikal već rezervisan tj. zauzet, to je označeno crvenom bojom.
