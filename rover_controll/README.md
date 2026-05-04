# Rover Control App (ESP32-CAM)

This Flutter project controls an ESP32-CAM rover over Wi-Fi.

Main capabilities:
1. Connect to rover (manual IP or auto detect)
2. Control movement and light
3. View live MJPEG camera stream
4. Configure and run optional on-device ML detection

This guide is for project sharing through Google Drive (without .git folder).

---

## 1. Minimum Requirements

1. Windows 10/11 (this guide is Windows-first)
2. At least 10 GB free disk space
3. Android phone with USB debugging enabled, or Android emulator
4. Stable Wi-Fi network for phone and rover

Recommended:
1. 16 GB RAM
2. VS Code or Android Studio

---

## 2. Install Flutter and Android Toolchain

### 2.1 Install Flutter SDK

1. Download Flutter SDK from:
https://docs.flutter.dev/get-started/install/windows
2. Extract to a path like:
`C:\src\flutter`
3. Add Flutter to PATH:
`C:\src\flutter\bin`

Open a new terminal and verify:

```powershell
flutter --version
```

### 2.2 Install Android Studio (recommended even if using VS Code)

1. Install Android Studio
2. Open Android Studio once and install:
	1. Android SDK
	2. Android SDK Platform
	3. Android SDK Command-line Tools
	4. Android SDK Build-Tools

### 2.3 Accept Android licenses

```powershell
flutter doctor --android-licenses
```

Type `y` for all prompts.

### 2.4 Verify environment

```powershell
flutter doctor
```

Resolve any items marked with `X` before continuing.

---

## 3. Install Optional IDE Extensions

If using VS Code, install:
1. Dart
2. Flutter

---

## 4. Get Project from Google Drive

1. Download and extract the project zip from Google Drive.
2. Place it in a normal local path (not inside OneDrive sync conflict folders), for example:
`C:\Users\<your-user>\Desktop\Flutter\rover_controll`
3. Open the folder in VS Code or Android Studio.

Important:
1. The project is shared without `.git` and this is fine.
2. Do not remove `.dart_tool` while app is running.

---

## 5. Install Dependencies

In the project root, run:

```powershell
flutter pub get
```

---

## 6. Generate Code (Only When Needed)

This project uses `injectable` and `freezed`.

You only need this command when changing annotated classes or generated models:

```powershell
dart run build_runner build --delete-conflicting-outputs
```

If you only run the app without changing model/DI annotations, this step is usually not required.

---

## 7. Run Static Checks

```powershell
dart analyze lib
flutter test
```

---

## 8. Prepare Device

### 8.1 Physical Android device

1. Enable Developer Options on phone
2. Enable USB debugging
3. Connect via USB
4. Verify device:

```powershell
flutter devices
```

### 8.2 Emulator (alternative)

1. Create and boot an Android emulator from Android Studio
2. Verify:

```powershell
flutter devices
```

---

## 9. First Successful Run

From the project root:

```powershell
flutter run
```

If multiple devices are connected:

```powershell
flutter run -d <device-id>
```

Expected result:
1. App launches to connection screen
2. Enter rover IP or use auto detect
3. Connect and navigate to rover control screen
4. Live stream and controls should be available if rover is online

---

## 10. Rover Network Requirements

1. Phone/emulator and ESP32-CAM rover must be on reachable network paths
2. Control endpoint uses port 80
3. Stream endpoint uses port 81 (`/stream`)

If stream fails but connection succeeds:
1. Verify rover power stability
2. Verify port 81 is reachable
3. Verify firmware stream server is running

---

## 11. Common Commands

```powershell
flutter pub get
dart analyze lib
flutter test
flutter run
flutter clean
```

If plugins fail after dependency changes:

```powershell
flutter clean
flutter pub get
flutter run
```

---

## 12. Troubleshooting

### Issue: `flutter` command not found
1. Recheck PATH includes `flutter\bin`
2. Restart terminal/VS Code

### Issue: Android licenses not accepted
1. Run `flutter doctor --android-licenses`

### Issue: Build fails on first run
1. Run `flutter clean`
2. Run `flutter pub get`
3. Run `flutter run`

### Issue: App connects but stream freezes or light resets
1. Most likely rover power stability issue (hardware-side)
2. Review firmware handoff doc:
	`docs/FIRMWARE_FIX_HANDOFF.md`

### Issue: ML not available on desktop/web
1. Current ML plugin targets Android/iOS runtime
2. App should continue with ML disabled mode

---

## 13. Project Documentation for Handover

Key docs:
1. Full project handover:
	`docs/PROJECT_HANDOVER_AI.md`
2. Firmware issue handoff:
	`docs/FIRMWARE_FIX_HANDOFF.md`
3. Firmware reference files:
	`docs/ESP32CAM_Car.ino`
	`docs/app_httpd.cpp`

---

## 14. Notes for Team Sharing via Google Drive

1. Share the entire project folder except `.git`
2. Receiver should run `flutter pub get` after extraction
3. If generated files are out of sync, run build_runner command in Section 6

That is all needed to set up from zero to successful run.
