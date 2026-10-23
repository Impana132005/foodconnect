@echo off
setlocal

:: ==============================================================================
:: FoodConnect - Quick App Runner (Windows)
:: ==============================================================================

cd /d "%~dp0\.."

echo ======================================================
echo           FoodConnect App Launcher (Windows)
echo ======================================================
echo.

echo Available connected devices:
call flutter devices
echo.

echo Select target platform to run:
echo   1) Default connected device (flutter run)
echo   2) Android Emulator / Device (flutter run -d android)
echo   3) Chrome Web (flutter run -d chrome)
echo   4) Windows Desktop (flutter run -d windows)
echo   5) Start Firebase Emulators (firebase emulators:start)
echo   q) Quit
echo.

set /p CHOICE="Enter choice [1-5, q]: "

if "%CHOICE%"=="1" (
    call flutter run
) else if "%CHOICE%"=="2" (
    call flutter run -d android
) else if "%CHOICE%"=="3" (
    call flutter run -d chrome
) else if "%CHOICE%"=="4" (
    call flutter run -d windows
) else if "%CHOICE%"=="5" (
    call firebase emulators:start
) else if /i "%CHOICE%"=="q" (
    echo Exiting.
    exit /b 0
) else (
    echo Invalid choice. Running default flutter run...
    call flutter run
)
