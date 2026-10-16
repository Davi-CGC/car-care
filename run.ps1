Write-Host "Iniciando CarCare no Google Chrome..." -ForegroundColor Yellow
Stop-Process -Name dart -Force -ErrorAction SilentlyContinue
flutter run -d chrome
