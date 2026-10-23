@echo off
setlocal enabledelayedexpansion

:: ==============================================================================
:: FoodConnect - Automated Project Setup Script for Windows (Command Prompt)
:: ==============================================================================

echo ======================================================
echo    FoodConnect Automated Environment ^& Setup Helper  
echo ======================================================
echo.

:: Navigate to root directory
cd /d "%~dp0\.."

set "ERRORS=0"

echo [1/4] Checking Required Tools ^& Environment...
echo.

:: Check Git
where git >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Git is installed.
) else (
    echo   [FAIL] Git is NOT installed. Please install from https://git-scm.com/
    set /a ERRORS+=1
)

:: Check Flutter
where flutter >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Flutter SDK is installed.
) else (
    echo   [FAIL] Flutter SDK is NOT in your PATH. Please install from https://docs.flutter.dev/get-started/install
    set /a ERRORS+=1
)

:: Check Dart
where dart >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Dart SDK is installed.
) else (
    echo   [FAIL] Dart SDK is NOT in your PATH.
    set /a ERRORS+=1
)

:: Check Java
where java >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Java Runtime is installed.
) else (
    echo   [FAIL] Java (JDK 17/21) is NOT installed. Please install Eclipse Temurin JDK 17.
    set /a ERRORS+=1
)

:: Check JAVA_HOME
if defined JAVA_HOME (
    echo   [OK] JAVA_HOME is set to: %JAVA_HOME%
) else (
    echo   [WARN] JAVA_HOME environment variable is not set. Please set JAVA_HOME in System Properties.
)

:: Check ANDROID_HOME
if defined ANDROID_HOME (
    echo   [OK] ANDROID_HOME is set to: %ANDROID_HOME%
) else (
    echo   [WARN] ANDROID_HOME is not set. (Usually %%LOCALAPPDATA%%\Android\Sdk)
)

:: Check Node.js
where node >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Node.js is installed.
) else (
    echo   [FAIL] Node.js is NOT installed. Please install Node.js v18/v20 LTS from https://nodejs.org/
    set /a ERRORS+=1
)

:: Check npm
where npm >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] npm is installed.
) else (
    echo   [FAIL] npm is NOT installed.
    set /a ERRORS+=1
)

:: Check Firebase CLI
where firebase >nul 2>&1
if %errorlevel% equ 0 (
    echo   [OK] Firebase CLI is installed.
) else (
    echo   [INFO] Firebase CLI is not installed globally. Install via: npm install -g firebase-tools
)

echo.
if %ERRORS% gtr 0 (
    echo [ERROR] %ERRORS% prerequisite check(s) failed.
    echo Please install the missing tools above and re-run this script.
    echo Refer to REQUIREMENTS.md for detailed instructions.
    pause
    exit /b 1
)

echo [2/4] Installing Flutter Dependencies...
call flutter clean
call flutter pub get
if %errorlevel% neq 0 (
    echo [ERROR] flutter pub get failed.
    pause
    exit /b 1
)
echo [OK] Flutter dependencies installed successfully.
echo.

echo [3/4] Installing Cloud Functions Dependencies in /functions...
if exist "functions\package.json" (
    pushd functions
    call npm install
    call npm run build
    popd
    echo [OK] Cloud Functions setup complete.
) else (
    echo [INFO] No functions directory found. Skipping.
)
echo.

echo [4/4] Running Flutter Doctor Diagnostics...
call flutter doctor
echo.

echo ======================================================
echo    Setup Completed Successfully!
echo ======================================================
echo.
echo Next Steps:
echo   1. Check connected devices:     flutter devices
echo   2. Run on Android emulator:     flutter run -d android
echo   3. Run on Chrome Web:           flutter run -d chrome
echo   4. Accept Android licenses:     flutter doctor --android-licenses
echo   5. Full guide:                  REQUIREMENTS.md
echo.
pause
