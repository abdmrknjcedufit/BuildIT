# BuildIT - Backend API

ASP.NET Core Web API aplikacija za prodaju i iznajmljivanje građevinskih mašina, alata i materijala.

## Tehnologije

- .NET 8.0
- ASP.NET Core Web API
- Entity Framework Core (Code First)
- SQL Server
- Mapster (object mapping)
- Swagger/OpenAPI

## Struktura projekta

```
backend/
├── Controllers/         # API kontroleri
├── Filters/            # Exception filteri
├── Model/              # Model klase, Request klase, SearchObject klase
├── Services/           # Business logika, Database entiteti, Helpers
└── Program.cs          # Konfiguracija aplikacije
```

## Baza podataka

### Connection String

Connection string se nalazi u `appsettings.json` i `appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "BuildITDB": "Data Source=AMR-PERFORMANCE\\LOCALHOST;Initial Catalog=RS2_BuildIT;User Id=sa;Password=QWEasd123!;TrustServerCertificate=True;Connect Timeout=30;Encrypt=True;"
  }
}
```

### Migracije

Za primjenu migracija:

```bash
dotnet ef migrations add MigrationName
dotnet ef database update
```

Aplikacija automatski primjenjuje migracije pri pokretanju.

## Pokretanje aplikacije

```bash
cd backend/backend
dotnet restore
dotnet run
```

Aplikacija će biti dostupna na:
- API: `https://localhost:5001` ili `http://localhost:5000`
- Swagger UI: `https://localhost:5001/swagger` ili `http://localhost:5000/swagger`

## Test korisnici

Aplikacija automatski kreira test korisnike pri prvom pokretanju:

### Desktop (Admin)
- **Username:** `desktop`
- **Password:** `test`
- **Role:** Admin
- **Pristup:** Samo desktop aplikacija

### Mobile (User)
- **Username:** `mobile`
- **Password:** `test`
- **Role:** User
- **Pristup:** Samo mobilna aplikacija

## API Endpoints

### Autentifikacija

- `POST /User/login` - Prijava korisnika
  - Automatski određuje tip klijenta (desktop/mobile) na osnovu role
  - Admin korisnici mogu se prijaviti samo sa desktop aplikacije
  - Obični korisnici mogu se prijaviti samo sa mobilne aplikacije

### Korisnici

- `GET /User` - Lista korisnika (sa paginacijom i pretragom)
- `GET /User/{id}` - Detalji korisnika
- `POST /User` - Registracija novog korisnika (AllowAnonymous)
- `PUT /User/{id}` - Ažuriranje korisnika
- `PATCH /User/{id}/status` - Promjena statusa korisnika (Admin only)
- `POST /User/{id}/reset-password` - Reset lozinke (Admin only)

### Autentifikacija u Swaggeru

Za pristup zaštićenim endpointima u Swaggeru:
1. Klikni na "Authorize" dugme (gore desno)
2. Unesi Basic Auth credentials:
   - Username: `desktop`
   - Password: `test`

## Validacija

### Lozinka

Lozinka mora ispunjavati sljedeće kriterijume:
- Najmanje 8 karaktera
- Najmanje jedno veliko slovo (A-Z)
- Najmanje jedno malo slovo (a-z)
- Najmanje jedan broj (0-9)
- Najmanje jedan specijalni karakter: `< > @ ! # $ % ^ & * + - = / | ~`

### Broj telefona

- Mora sadržavati samo cifre
- Dužina: 9 ili 10 cifara

### Korisničko ime

- Mora biti jedinstveno u bazi
- Ne može se promijeniti nakon registracije
- Case-insensitive validacija

## Pravila

- Admin korisnici mogu se prijaviti samo iz desktop aplikacije
- Obični korisnici mogu se prijaviti samo iz mobilne aplikacije
- Username se može postaviti samo jednom pri registraciji
- Admin korisnici ne mogu biti deaktivirani
- Lozinka se čuva kao hash (SHA1) sa salt-om

## Razvoj

### Dodavanje novih entiteta

1. Kreiraj Database entitet u `Services/Database/`
2. Kreiraj Model klasu u `Model/Models/`
3. Kreiraj Request klase (Insert/Update) u `Model/Requests/`
4. Kreiraj SearchObject klasu u `Model/SearchObjects/`
5. Kreiraj Service koji nasleđuje `BaseCRUDService` u `Services/Services/`
6. Kreiraj Interface u `Services/Interfaces/`
7. Kreiraj Controller koji nasleđuje `BaseCRUDController`
8. Registruj Service u `Program.cs`
9. Dodaj DbSet u `BuildITDbContext`
10. Konfiguriši entitet u `OnModelCreating` metodi
11. Kreiraj migraciju: `dotnet ef migrations add AddEntityName`

## Napomene

- Sve poruke grešaka su na bosanskom jeziku (ijekavica)
- Aplikacija koristi Basic Authentication
- Exception handling se vrši kroz `ExceptionFilter`
- Seed podaci se automatski kreiraju pri prvom pokretanju

