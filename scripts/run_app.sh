#!/usr/bin/env bash

# ==============================================================================
# FoodConnect - Quick App Runner (macOS / Linux)
# ==============================================================================

set -e

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo -e "${CYAN}${BOLD}======================================================"
echo -e "          🍔 FoodConnect App Launcher               "
echo -e "======================================================${NC}\n"

echo -e "Available connected devices & emulators:"
flutter devices
echo ""

echo -e "${BOLD}Select target platform to run:${NC}"
echo "1) Default connected device (flutter run)"
echo "2) Android Emulator / Device (flutter run -d android)"
echo "3) iOS Simulator / Device (macOS only) (flutter run -d ios)"
echo "4) Chrome Web (flutter run -d chrome)"
echo "5) macOS Desktop (flutter run -d macos)"
echo "6) Start Firebase Emulators Suite (firebase emulators:start)"
echo "q) Quit"
echo ""

read -p "Enter choice [1-6, q]: " CHOICE

case "$CHOICE" in
    1)
        flutter run
        ;;
    2)
        flutter run -d android
        ;;
    3)
        flutter run -d ios
        ;;
    4)
        flutter run -d chrome
        ;;
    5)
        flutter run -d macos
        ;;
    6)
        firebase emulators:start
        ;;
    q|Q)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo -e "${YELLOW}Invalid option. Running default flutter run...${NC}"
        flutter run
        ;;
esac
