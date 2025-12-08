# BuildIT Desktop

Desktop aplikacija za BuildIT - Prodaja i iznajmljivanje građevinskog materijala.

## Preduvjeti

- Flutter SDK instaliran na `C:\Users\Abdullah\Desktop\flutter sdk\flutter`
- Backend API pokrenut na `http://localhost:5031/`

## Postavljanje Flutter PATH-a

### Opcija 1: Trajno dodavanje (preporučeno)

Pokreni PowerShell kao Administrator i izvrši:
```powershell
.\SETUP_FLUTTER_PATH.ps1
```
Zatim restartuj terminal.

### Opcija 2: Privremeno za ovu sesiju

U PowerShell terminalu:
```powershell
$env:PATH += ";C:\Users\Abdullah\Desktop\flutter sdk\flutter\bin"
```

## Pokretanje

### Brzo pokretanje (preporučeno)
Dvostruki klik na `RUN_APP.bat` fajl.

### Ručno pokretanje

```bash
# Dodaj Flutter u PATH (ako nije trajno dodan)
$env:PATH += ";C:\Users\Abdullah\Desktop\flutter sdk\flutter\bin"

# Instaliraj dependencies
flutter pub get

# Pokreni aplikaciju
flutter run -d windows --dart-define=baseUrl=http://localhost:5031/
```

## Test login podaci

- **Admin:**
  - Username: `desktop`
  - Password: `test`

- **Korisnik:**
  - Username: `mobile`
  - Password: `test`

## Struktura projekta

- `lib/models/` - Modeli podataka
- `lib/providers/` - Provideri za API pozive
- `lib/screens/` - Ekrani aplikacije
- `lib/widgets/` - Reusable widgeti
- `lib/utils/` - Utility funkcije
- `lib/app_colors.dart` - Boje aplikacije

## Konfiguracija

Base URL se postavlja preko `--dart-define=baseUrl=...` prilikom pokretanja aplikacije.

