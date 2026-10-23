#!/usr/bin/env bash

# ==============================================================================
# FoodConnect - Automated Project Setup Script (macOS / Linux / Git Bash)
# ==============================================================================

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Determine project root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${CYAN}${BOLD}======================================================"
echo -e "   🍔 FoodConnect Automated Environment & Setup Helper  "
echo -e "======================================================${NC}\n"

ERRORS=0
WARNINGS=0

# Helper functions
check_cmd() {
    local cmd_name="$1"
    local friendly_name="$2"
    local install_hint="$3"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        local version
        version=$($cmd_name --version 2>&1 | head -n 1 || echo "installed")
        echo -e "  [${GREEN}✔${NC}] $friendly_name found: ${BLUE}$version${NC}"
        return 0
    else
        echo -e "  [${RED}✖${NC}] $friendly_name is NOT installed."
        if [ -n "$install_hint" ]; then
            echo -e "      ${YELLOW}→ Action: $install_hint${NC}"
        fi
        ((ERRORS++))
        return 1
    fi
}

check_optional_cmd() {
    local cmd_name="$1"
    local friendly_name="$2"
    local install_hint="$3"

    if command -v "$cmd_name" >/dev/null 2>&1; then
        local version
        version=$($cmd_name --version 2>&1 | head -n 1 || echo "installed")
        echo -e "  [${GREEN}✔${NC}] $friendly_name found: ${BLUE}$version${NC}"
        return 0
    else
        echo -e "  [${YELLOW}⚠${NC}] $friendly_name is not detected (Optional / Platform-dependent)."
        if [ -n "$install_hint" ]; then
            echo -e "      ${YELLOW}→ Note: $install_hint${NC}"
        fi
        ((WARNINGS++))
        return 1
    fi
}

# ------------------------------------------------------------------------------
# 1. System & Environment Check
# ------------------------------------------------------------------------------
echo -e "${BOLD}[1/5] Checking Required Tools & Environment...${NC}"

# Check Git
check_cmd "git" "Git" "Install Git via brew install git or https://git-scm.com/"

# Check Flutter
check_cmd "flutter" "Flutter SDK" "Download Flutter SDK from https://docs.flutter.dev/get-started/install"

# Check Dart
check_cmd "dart" "Dart SDK" "Bundled with Flutter SDK. Ensure flutter/bin is in PATH."

# Check Java
check_cmd "java" "Java Runtime (JDK 17/21 recommended)" "Install OpenJDK 17/21 (e.g., brew install openjdk@17)"
if [ -z "$JAVA_HOME" ]; then
    echo -e "      ${YELLOW}⚠ JAVA_HOME environment variable is not explicitly set.${NC}"
    if [[ "$OSTYPE" == "darwin"* ]] && [ -x /usr/libexec/java_home ]; then
        DETECTED_JAVA_HOME=$(/usr/libexec/java_home 2>/dev/null || true)
        if [ -n "$DETECTED_JAVA_HOME" ]; then
            echo -e "      ${GREEN}→ Suggested macOS fix: export JAVA_HOME=\$(/usr/libexec/java_home -v 17)${NC}"
        fi
    fi
    ((WARNINGS++))
else
    echo -e "      ${GREEN}JAVA_HOME: $JAVA_HOME${NC}"
fi

# Check Node.js and npm
check_cmd "node" "Node.js (for Cloud Functions)" "Install Node.js v18/v20 LTS from https://nodejs.org or via brew install node@20"
check_cmd "npm" "npm" "Bundled with Node.js"

# Check Firebase CLI
check_optional_cmd "firebase" "Firebase CLI" "Install via: npm install -g firebase-tools"

# OS Specific Checks
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "\n${BOLD}macOS Specific Checks (iOS / macOS target):${NC}"
    check_optional_cmd "xcodebuild" "Xcode CLI Tools" "Install Xcode from App Store and run: sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer"
    check_optional_cmd "pod" "CocoaPods" "Install CocoaPods via: brew install cocoapods OR sudo gem install cocoapods"
fi

echo ""
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}${BOLD}✖ Environment checks failed with $ERRORS missing prerequisite(s).${NC}"
    echo -e "Please install the missing tools above and re-run this script."
    echo -e "Refer to ${BOLD}REQUIREMENTS.md${NC} for full instructions.\n"
    exit 1
fi

# ------------------------------------------------------------------------------
# 2. Flutter Dependencies
# ------------------------------------------------------------------------------
echo -e "${BOLD}[2/5] Installing Flutter Dependencies...${NC}"
flutter clean
flutter pub get
echo -e "${GREEN}✔ Flutter dependencies installed successfully.${NC}\n"

# ------------------------------------------------------------------------------
# 3. CocoaPods Setup (macOS only)
# ------------------------------------------------------------------------------
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "${BOLD}[3/5] Setting up iOS / macOS CocoaPods...${NC}"
    if command -v pod >/dev/null 2>&1; then
        if [ -d "ios" ]; then
            echo -e "Running pod install in ios/..."
            (cd ios && pod install)
            echo -e "${GREEN}✔ iOS CocoaPods installed successfully.${NC}"
        fi
        if [ -d "macos" ]; then
            echo -e "Running pod install in macos/..."
            (cd macos && pod install)
            echo -e "${GREEN}✔ macOS CocoaPods installed successfully.${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ Skipping CocoaPods installation (pod command not found).${NC}"
    fi
    echo ""
else
    echo -e "${BOLD}[3/5] Skipping CocoaPods (Non-macOS platform).${NC}\n"
fi

# ------------------------------------------------------------------------------
# 4. Backend Cloud Functions Dependencies
# ------------------------------------------------------------------------------
echo -e "${BOLD}[4/5] Setting up Backend Cloud Functions in /functions...${NC}"
if [ -d "functions" ] && [ -f "functions/package.json" ]; then
    (
        cd functions
        echo -e "Installing npm packages for Cloud Functions..."
        npm install
        if npm run | grep -q "build"; then
            echo -e "Building TypeScript functions..."
            npm run build
        fi
    )
    echo -e "${GREEN}✔ Cloud Functions setup complete.${NC}\n"
else
    echo -e "${YELLOW}⚠ No functions directory found. Skipping.${NC}\n"
fi

# ------------------------------------------------------------------------------
# 5. Flutter Doctor Diagnostics
# ------------------------------------------------------------------------------
echo -e "${BOLD}[5/5] Running Flutter Doctor Diagnostics...${NC}"
flutter doctor

echo -e "\n${GREEN}${BOLD}======================================================"
echo -e "   🎉 FoodConnect Setup Completed Successfully!       "
echo -e "======================================================${NC}\n"

echo -e "${BOLD}Next Steps:${NC}"
echo -e "  1. Check connected devices:     ${CYAN}flutter devices${NC}"
echo -e "  2. Run the application:         ${CYAN}flutter run${NC} (or ${CYAN}./scripts/run_app.sh${NC})"
echo -e "  3. Accept Android licenses:     ${CYAN}flutter doctor --android-licenses${NC} (if prompted)"
echo -e "  4. Optional Local Emulators:    ${CYAN}firebase emulators:start${NC}"
echo -e "  5. Consult full guide:          ${CYAN}REQUIREMENTS.md${NC}\n"
