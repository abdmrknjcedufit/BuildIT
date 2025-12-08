@echo off
REM Dodaj Flutter u PATH za ovu sesiju
set PATH=%PATH%;C:\Users\Abdullah\Desktop\flutter sdk\flutter\bin

REM Navigiraj u projekat
cd /d "%~dp0"

REM Instaliraj dependencies
echo Installing dependencies...
flutter pub get

REM Pokreni aplikaciju
echo Starting application...
flutter run -d windows --dart-define=baseUrl=http://localhost:5031/

pause

