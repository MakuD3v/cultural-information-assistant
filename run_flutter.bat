@echo off
title Run Flutter Mobile Application
echo ========================================================
echo  Running Flutter Mobile Application
echo ========================================================

cd /d "%~dp0\flutter_app"

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [NOTICE] Flutter SDK was not found in your system PATH.
    echo To run the native Flutter app:
    echo 1. Install Flutter SDK from https://docs.flutter.dev/get-started/install/windows
    echo 2. Add flutter\bin to your Environment PATH.
    echo 3. Re-run this script or type: flutter run
    echo.
    echo In the meantime, you can run the full app directly in your browser:
    echo Opening http://localhost:8000/app/
    start http://localhost:8000/app/
    pause
    exit /b
)

echo Fetching dependencies...
flutter pub get

echo Launching app...
flutter run
pause
