@echo off
echo ==========================================
echo   CarCare - Iniciando no Google Chrome
echo ==========================================
taskkill /F /IM dart.exe >nul 2>&1
flutter run -d chrome
