# Skripta za dodavanje Flutter SDK-a u PATH
# Pokreni ovu skriptu kao Administrator

$flutterPath = "C:\Users\Abdullah\Desktop\flutter sdk\flutter\bin"
$currentPath = [Environment]::GetEnvironmentVariable("Path", "User")

if ($currentPath -notlike "*$flutterPath*") {
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$flutterPath", "User")
    Write-Host "Flutter SDK je uspješno dodat u PATH!" -ForegroundColor Green
    Write-Host "Molimo restartujte terminal da bi promjene bile aktivne." -ForegroundColor Yellow
} else {
    Write-Host "Flutter SDK je već u PATH-u." -ForegroundColor Green
}

Write-Host "`nProvjerite sa: flutter --version" -ForegroundColor Cyan

