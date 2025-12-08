# Pokretanje BuildIT Desktop aplikacije u Android Studio

## Preduvjeti

1. **Android Studio instaliran** sa Flutter pluginom
2. **Flutter SDK** na lokaciji: `C:\Users\Abdullah\Desktop\flutter sdk\flutter`
3. **Backend API** pokrenut na `http://localhost:5031/`

## Korak 1: Otvori projekat u Android Studio

1. Pokreni **Android Studio**
2. Klikni **File → Open**
3. Navigiraj do: `C:\Users\Abdullah\Desktop\BuildIT\BuildIT\UI\buildit_desktop`
4. Klikni **OK**

## Korak 2: Konfiguriši Flutter SDK

1. Klikni **File → Settings** (ili `Ctrl + Alt + S`)
2. U lijevom meniju, idi na **Languages & Frameworks → Flutter**
3. U polju **Flutter SDK path**, klikni na ikonu folder i odaberi:
   ```
   C:\Users\Abdullah\Desktop\flutter sdk\flutter
   ```
4. Klikni **Apply** i **OK**

## Korak 3: Postavi Run konfiguraciju

1. Na vrhu Android Studio-a, pronađi dropdown sa run konfiguracijama (pored play dugmeta)
2. Ako već postoji **main.dart** konfiguracija, odaberi je
3. Ako ne postoji:
   - Klikni na dropdown → **Edit Configurations...**
   - Klikni **+** → **Flutter**
   - Ime: `main.dart`
   - Dart entrypoint: `lib/main.dart`
   - Additional run args: `--dart-define=baseUrl=http://localhost:5031/`
   - Target device: `windows`
   - Klikni **OK**

## Korak 4: Odaberi Windows kao target device

1. Na vrhu Android Studio-a, pronađi dropdown za odabir uređaja
2. Klikni na dropdown
3. Odaberi **windows** (Windows Desktop)
4. Ako ne vidiš Windows opciju:
   - Klikni **Device Manager** (ikonica telefona)
   - Provjeri da li je Windows desktop podrška omogućena

## Korak 5: Pokreni aplikaciju

1. Klikni na **Run** dugme (zeleni play) ili pritisni `Shift + F10`
2. Aplikacija će se kompajlirati i pokrenuti (može potrajati 1-2 minute prvi put)

## Troubleshooting

### Flutter SDK nije pronađen
- Provjeri da li je Flutter SDK na lokaciji: `C:\Users\Abdullah\Desktop\flutter sdk\flutter`
- Provjeri da li postoji `flutter.bat` u `bin` folderu

### Windows device nije dostupan
- Provjeri da li je Windows desktop podrška omogućena u Flutter SDK-u
- U terminalu pokreni: `flutter doctor` da provjeriš konfiguraciju

### Build greške
- Klikni **File → Invalidate Caches / Restart**
- Odaberi **Invalidate and Restart**

### Backend nije dostupan
- Provjeri da li je backend pokrenut na `http://localhost:5031/`
- Provjeri u browseru: `http://localhost:5031/swagger` (ako je Swagger omogućen)

## Hot Reload

Nakon što se aplikacija pokrene, možeš koristiti:
- **Hot Reload**: `Ctrl + \` ili klikni na ikonu 🔥
- **Hot Restart**: `Ctrl + Shift + \` ili klikni na ikonu 🔄

## Debugging

Za debugging:
1. Postavi breakpointe klikom na lijevu marginu pored linije koda
2. Pokreni aplikaciju u debug modu (ikonica buba 🐛)
3. Aplikacija će se zaustaviti na breakpointu

