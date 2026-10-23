# FoodConnect — System Requirements & Environment Setup Guide

This guide contains everything required to clone, configure, and run the **FoodConnect** project on a new laptop running either **macOS** or **Windows**.

---

## 📋 System Requirements Overview

| Component | Minimum / Recommended Version | Purpose |
| :--- | :--- | :--- |
| **OS** | macOS 13+ (Ventura/Sonoma/Sequoia) or Windows 10/11 (64-bit) | Operating System |
| **RAM** | 8 GB minimum (16 GB recommended for Emulators) | Memory |
| **Disk Space** | ~15-20 GB free space | SDKs, Emulators, & Tools |
| **Flutter SDK** | **3.29.x** or latest stable (Dart SDK `^3.11.x`) | Frontend Framework |
| **Java JDK** | **JDK 17** or **JDK 21** (Temurin / OpenJDK) | Android Build / Gradle |
| **Android Studio** | Latest version (with SDK 34/35, Command-line Tools) | Android Build & Emulator |
| **Node.js & npm** | Node.js **v18 LTS** or **v20 LTS** & npm **v9+** | Cloud Functions & Firebase Tools |
| **Firebase CLI** | Latest (`npm install -g firebase-tools`) | Firebase & Emulators |
| **Xcode & CocoaPods** *(macOS only)* | Xcode 15+ & CocoaPods 1.13+ | iOS / macOS Builds |
| **Visual Studio C++** *(Windows only)* | VS 2022 Community (Desktop development with C++) | Windows Desktop Build (Optional) |

---

## 🚀 Quick Automated Setup

We provide automated setup scripts that verify your environment, install Flutter packages, set up iOS CocoaPods (macOS), and configure backend functions:

### On macOS / Linux / Git Bash:
```bash
# Make script executable (first time only)
chmod +x scripts/setup.sh scripts/run_app.sh

# Run setup
./scripts/setup.sh
```

### On Windows (Command Prompt or PowerShell):
```cmd
:: In Command Prompt (cmd)
.\scripts\setup.bat

:: OR in PowerShell (Run as Administrator if needed)
.\scripts\setup.ps1
```

---

## 🛠️ Step-by-Step Manual Setup

### 1. Git & Flutter SDK
1. **Install Git**:
   - **macOS**: `brew install git` or via Xcode Command Line Tools (`xcode-select --install`).
   - **Windows**: Download from [git-scm.com](https://git-scm.com/).
2. **Install Flutter**:
   - Download the Flutter SDK from [flutter.dev](https://docs.flutter.dev/get-started/install).
   - Extract and add `flutter/bin` to your system `PATH`.
   - Test in terminal:
     ```bash
     flutter --version
     ```

---

### 2. Java JDK Configuration (Critical for Android)
Android Gradle build requires **JDK 17** or **JDK 21**.

- **macOS**:
  ```bash
  brew install openjdk@17
  # Add to ~/.zshrc:
  export JAVA_HOME=$(/usr/libexec/java_home -v 17)
  export PATH="$JAVA_HOME/bin:$PATH"
  ```
- **Windows**:
  - Download [Eclipse Temurin JDK 17](https://adoptium.net/temurin/releases/?version=17).
  - Set Environment Variable `JAVA_HOME` to `C:\Program Files\Eclipse Adoptium\jdk-17.x.x`.
  - Add `%JAVA_HOME%\bin` to your `Path`.

---

### 3. Android Studio & Android SDK Setup
1. Download and install [Android Studio](https://developer.android.com/studio).
2. Open **Android Studio** -> **Settings / Preferences** -> **Languages & Frameworks** -> **Android SDK**:
   - **SDK Platforms**: Check `Android 14 (API 34)` and/or `Android 15 (API 35)`.
   - **SDK Tools Tab**: Check:
     - `Android SDK Build-Tools`
     - `Android SDK Command-line Tools (latest)`
     - `Android SDK Platform-Tools`
     - `Android Emulator`
3. Set environment variables:
   - **macOS (`~/.zshrc`)**:
     ```bash
     export ANDROID_HOME=$HOME/Library/Android/sdk
     export PATH=$PATH:$ANDROID_HOME/emulator
     export PATH=$PATH:$ANDROID_HOME/platform-tools
     export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin
     ```
   - **Windows**:
     - Variable Name: `ANDROID_HOME`
     - Variable Value: `C:\Users\<YourUsername>\AppData\Local\Android\Sdk`
     - Add to `Path`: `%ANDROID_HOME%\platform-tools`, `%ANDROID_HOME%\emulator`
4. Accept Android Licenses:
   ```bash
   flutter doctor --android-licenses
   ```

---

### 4. Node.js, npm & Firebase CLI
Required for the Cloud Functions located in `/functions` and Firebase local emulator suite.

1. **Install Node.js (v18 or v20 LTS)**:
   - **macOS**: `brew install node@20` or use `nvm install 20`.
   - **Windows**: Download installer from [nodejs.org](https://nodejs.org/).
2. **Install Firebase CLI globally**:
   ```bash
   npm install -g firebase-tools
   ```
3. **Login to Firebase**:
   ```bash
   firebase login
   ```
4. **Install Functions Dependencies**:
   ```bash
   cd functions
   npm install
   npm run build
   cd ..
   ```

---

### 5. macOS Only: iOS & CocoaPods Setup
1. **Install Xcode** from Mac App Store.
2. Install Command Line Tools & accept license:
   ```bash
   sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
   sudo xcodebuild -runFirstLaunch
   sudo xcodebuild -license accept
   ```
3. **Install CocoaPods**:
   ```bash
   sudo gem install cocoapods
   # Or using Homebrew:
   brew install cocoapods
   ```
4. **Install iOS Pods**:
   ```bash
   cd ios
   pod install
   cd ..
   ```

---

## 📱 Running the Application

### 1. Launch Emulators / Simulators
- **Android**: Launch an Android Virtual Device (AVD) from Android Studio Device Manager or via CLI:
  ```bash
  emulator -list-avds
  emulator -avd <avd_name>
  ```
- **iOS (macOS only)**:
  ```bash
  open -a Simulator
  ```

### 2. Run the App
```bash
# Check connected devices
flutter devices

# Run on default connected device
flutter run

# Run on specific target
flutter run -d android
flutter run -d ios        # macOS only
flutter run -d chrome     # Web
```

### 3. Local Firebase Emulators (Optional Backend Testing)
```bash
# Start Firestore and Functions emulators locally
firebase emulators:start
```

---

## ❓ Troubleshooting & FAQs

### Q1: `flutter doctor` shows Android license status unknown
**Fix**:
1. Open Android Studio -> SDK Manager -> SDK Tools -> Check **Android SDK Command-line Tools (latest)** -> Apply.
2. Run `flutter doctor --android-licenses` and accept all prompts (`y`).

### Q2: Gradle build fails with `Unsupported class file major version` or Java errors
**Fix**: Ensure your `JAVA_HOME` points to JDK 17 or JDK 21 (Gradle 8.x is incompatible with JDK 22+ in some legacy plugins).
Check with: `java -version`.

### Q3: CocoaPods error on macOS (`pod install` fails)
**Fix**:
```bash
cd ios
rm -rf Pods Podfile.lock .symlinks
pod cache clean --all
pod repo update
pod install
cd ..
```

### Q4: Firebase services fail to initialize
**Fix**:
- For Android: Ensure `android/app/google-services.json` is present.
- For iOS: Ensure `ios/Runner/GoogleService-Info.plist` is linked in Xcode if running natively on iOS.
- For Cloud Functions: Ensure you ran `npm install` inside `/functions`.
