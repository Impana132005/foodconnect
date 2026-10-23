# ==============================================================================
# FoodConnect - Automated Project Setup Script for Windows (PowerShell)
# ==============================================================================

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "   🍔 FoodConnect Automated Environment & Setup Helper  " -ForegroundColor Cyan
Write-Host "======================================================`n" -ForegroundColor Cyan

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectRoot = Resolve-Path "$ScriptDir\.."
Set-Location $ProjectRoot

$ErrorsCount = 0
$WarningsCount = 0

function Test-Executable ($Cmd, $Name, $Hint) {
    if (Get-Command $Cmd -ErrorAction SilentlyContinue) {
        $version = try { (& $Cmd --version 2>&1 | Select-Object -First 1) } catch { "installed" }
        Write-Host "  [✔] $Name found: $version" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  [✖] $Name is NOT installed or not in PATH." -ForegroundColor Red
        if ($Hint) {
            Write-Host "      → Action: $Hint" -ForegroundColor Yellow
        }
        $script:ErrorsCount++
        return $false
    }
}

function Test-OptionalExecutable ($Cmd, $Name, $Hint) {
    if (Get-Command $Cmd -ErrorAction SilentlyContinue) {
        $version = try { (& $Cmd --version 2>&1 | Select-Object -First 1) } catch { "installed" }
        Write-Host "  [✔] $Name found: $version" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  [⚠] $Name is not installed (Optional / Feature specific)." -ForegroundColor Yellow
        if ($Hint) {
            Write-Host "      → Note: $Hint" -ForegroundColor Yellow
        }
        $script:WarningsCount++
        return $false
    }
}

# 1. System checks
Write-Host "[1/4] Checking Required Tools & Environment..." -ForegroundColor White

Test-Executable "git" "Git" "Download and install from https://git-scm.com/"
Test-Executable "flutter" "Flutter SDK" "Download from https://docs.flutter.dev/get-started/install and add flutter\bin to PATH"
Test-Executable "dart" "Dart SDK" "Ensure flutter\bin is added to system PATH."
Test-Executable "java" "Java Runtime (JDK 17/21)" "Install Eclipse Temurin JDK 17 or OpenJDK 17"
Test-Executable "node" "Node.js (v18/v20 LTS)" "Download installer from https://nodejs.org/"
Test-Executable "npm" "npm" "Bundled with Node.js"
Test-OptionalExecutable "firebase" "Firebase CLI" "Install via: npm install -g firebase-tools"

# Environment Variables
if ($env:JAVA_HOME) {
    Write-Host "  [✔] JAVA_HOME: $env:JAVA_HOME" -ForegroundColor Green
} else {
    Write-Host "  [⚠] JAVA_HOME environment variable is not set." -ForegroundColor Yellow
    $WarningsCount++
}

if ($env:ANDROID_HOME) {
    Write-Host "  [✔] ANDROID_HOME: $env:ANDROID_HOME" -ForegroundColor Green
} else {
    Write-Host "  [⚠] ANDROID_HOME is not set. Default SDK path is usually %LOCALAPPDATA%\Android\Sdk" -ForegroundColor Yellow
}

Write-Host ""
if ($ErrorsCount -gt 0) {
    Write-Host "✖ Environment check failed with $ErrorsCount missing tool(s)." -ForegroundColor Red
    Write-Host "Please install the missing tools and re-run this script." -ForegroundColor Red
    Write-Host "Refer to REQUIREMENTS.md for full guidance.`n" -ForegroundColor Yellow
    Exit 1
}

# 2. Flutter Pub Get
Write-Host "[2/4] Installing Flutter Dependencies..." -ForegroundColor White
flutter clean
flutter pub get
if ($LASTEXITCODE -ne 0) {
    Write-Host "✖ flutter pub get failed." -ForegroundColor Red
    Exit 1
}
Write-Host "✔ Flutter dependencies installed successfully.`n" -ForegroundColor Green

# 3. Functions NPM Setup
Write-Host "[3/4] Setting up Cloud Functions in /functions..." -ForegroundColor White
if (Test-Path "functions\package.json") {
    Push-Location "functions"
    npm install
    npm run build
    Pop-Location
    Write-Host "✔ Cloud Functions setup complete.`n" -ForegroundColor Green
} else {
    Write-Host "⚠ No functions directory found. Skipping.`n" -ForegroundColor Yellow
}

# 4. Flutter Doctor
Write-Host "[4/4] Running Flutter Doctor Diagnostics..." -ForegroundColor White
flutter doctor

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "   🎉 FoodConnect Setup Completed Successfully!       " -ForegroundColor Green
Write-Host "======================================================`n" -ForegroundColor Green

Write-Host "Next Steps:" -ForegroundColor White
Write-Host "  1. Check connected devices:     flutter devices" -ForegroundColor Cyan
Write-Host "  2. Run on Android emulator:     flutter run -d android" -ForegroundColor Cyan
Write-Host "  3. Run on Chrome Web:           flutter run -d chrome" -ForegroundColor Cyan
Write-Host "  4. Accept Android licenses:     flutter doctor --android-licenses" -ForegroundColor Cyan
Write-Host "  5. Full guide:                  REQUIREMENTS.md`n" -ForegroundColor Cyan
