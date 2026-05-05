# ROVER — Real-time Online Vehicular Exploration Robot
### ESP32-CAM Wi-Fi Surveillance Smart Car
**ES 130 · BSCS-3A · Western Mindanao State University, Zamboanga City**

> Developed by: Amin, Ionyjal Aziz F. · Idulsa, Emman Nicholas B. · Seupon, Paul Adrian P. · Valeros, Vladimir C. II

---

## Table of Contents

1. [Overview](#1-overview)
2. [Problem](#2-problem)
3. [Our Solution](#3-our-solution)
4. [Features](#4-features)
5. [Components](#5-components)
6. [Architecture](#6-architecture)
7. [Setup & Installation](#7-setup--installation)
8. [Standard Operating Procedure](#8-standard-operating-procedure)

---

## 1. Overview

ROVER (Real-time Online Vehicular Exploration Robot) is a 4WD Wi-Fi-enabled surveillance smart car powered by the ESP32-CAM microcontroller. It streams live video and accepts real-time directional commands through a Flutter Android application, developed as an academic embedded systems project for ES 130, BSCS-3A at WMSU, Zamboanga City.

The system is built around a single ESP32-CAM module that acts simultaneously as the car's control brain and its camera eye. It connects to a mobile hotspot, starts an HTTP command server and a dedicated MJPEG camera stream server, and waits for commands from the Flutter companion app. The Flutter app handles all user interaction — motor control, LED toggling, and on-device computer vision — without requiring any third-party backend or internet connection.

**Project Status:** Fully functional as of April 30, 2026. All core features are operational.

---

## 2. Problem

Remote monitoring and vehicular control in embedded systems typically require costly, complex hardware setups or proprietary software ecosystems inaccessible to undergraduate students. Existing platforms either lack live camera integration, require specialized programming environments, or depend on expensive dedicated hardware controllers.

Students in embedded systems courses need a low-cost, hands-on platform that meaningfully integrates live camera streaming, real-time wireless motor control, and intelligent computer vision — all within a single compact device that can be built, debugged, and extended without significant infrastructure.

Beyond hardware, the software gap is equally significant. Most hobbyist surveillance car projects rely on simple browser-based web UIs with no persistent logic, no stream recovery, and no on-device intelligence. The ROVER project addresses both the hardware and software layers simultaneously: an affordable ESP32-CAM-based chassis paired with a production-grade Flutter Android application that includes automatic rover discovery, stream watchdog recovery, and on-device ML inference.

---

## 3. Our Solution

ROVER combines an ESP32-CAM with a Flutter Android app — delivering real-time Wi-Fi motor control and live MJPEG camera streaming with on-device computer vision such as object detection, motion detection, and CV overlays.

### Key Design Decisions

**Single-chip architecture.** The ESP32-CAM serves as both the microcontroller and the camera module, eliminating the need for a separate camera interface board or additional compute unit. Its integrated Wi-Fi makes it a self-contained node on the local hotspot network.

**Flutter over browser UI.** The companion app was deliberately built in Flutter rather than served as a browser page from the ESP32. This decision unlocks on-device ML inference via Google ML Kit, persistent connection state management, automatic rover IP discovery, and a stream watchdog — none of which are achievable in a static HTML page served from the ESP32's limited flash.

**Mobile hotspot networking.** Rather than running the ESP32 in Access Point (AP) mode, the car connects to a phone's mobile hotspot. This means both the phone running the Flutter app and the rover share the same subnet, enabling direct IP communication. It also keeps the ESP32 in station (STA) mode, which is more stable under sustained motor load.

**HTTP GET command protocol.** Motor control commands are sent as simple HTTP GET requests to the ESP32's Port 80 server. This approach is stateless, requires no WebSocket handshake, and is trivially implemented on both the ESP32 (via the existing `app_httpd.cpp` handler) and the Flutter client (via standard HTTP). The trade-off — slightly higher latency than WebSocket — is acceptable for a 4WD car at this speed range.

**On-device ML.** All computer vision processing runs entirely on the Android device inside the Flutter app. The ESP32 has no ML capability; it only streams raw MJPEG frames. The Flutter app decodes those frames, passes them to Google ML Kit and a frame-differencing pipeline, and renders overlays on a canvas — keeping the ESP32 completely unmodified.

---

## 4. Features

### Object Detection
Flutter runs Google ML Kit object detection and overlays bounding box labels on the live MJPEG camera feed.

The Flutter app uses `google_mlkit_object_detection` to run on-device inference against each decoded MJPEG frame. The ML Kit model is a MobileNet-based classifier capable of detecting and labeling dozens of object categories in real time, including people, vehicles, animals, and everyday objects. Detected objects are drawn as labeled bounding boxes directly on the camera canvas with no perceptible latency on mid-range Android hardware. The feature supports three modes — Off, General, and Person-only — switchable from the ML Settings screen. Confidence threshold and detection interval (in milliseconds) are also configurable.

### Motion Detection
Motion detection in Flutter compares video frames to highlight detected movement on the live camera stream.

A frame-differencing algorithm runs in the Flutter app alongside the MJPEG decoder. Each incoming frame is compared against the previous one at the pixel level. Regions where the per-channel difference exceeds a configurable threshold are highlighted with an orange overlay, and a red "MOTION DETECTED" banner appears when aggregate motion crosses a sensitivity floor. This feature requires no ML model — it runs as pure Dart logic on decoded image bytes — making it extremely lightweight and compatible with all Android devices regardless of ML Kit hardware acceleration support. It is particularly effective for stationary surveillance use cases where the rover is parked and monitoring an area.

### Smart Controls
Hold-to-move D-pad controls, LED toggle, automatic IP discovery, and a live stream watchdog in Flutter app.

The Flutter control interface provides a four-direction D-pad where each button uses a hold-to-move paradigm: pressing a button starts movement after a 150ms debounce delay, and releasing it immediately sends a stop command. This mirrors the physical behavior expected of a remote-controlled vehicle and prevents accidental single taps from triggering unwanted movement.

Additional smart control features include:

- **Automatic IP Discovery** — On connection, the Flutter app performs a batched subnet scan (24 concurrent hosts), fingerprinting responses by matching the ESP32's HTML content signature. Users never need to manually enter an IP address.
- **LED Flash Toggle** — The onboard ESP32-CAM LED flash can be toggled on or off from the app. A keep-alive mechanism re-sends the LED state every 8 seconds to prevent the ESP32 from reverting due to watchdog resets.
- **Stream Watchdog** — The MJPEG stream decoder monitors frame arrival rate. If no new frame is received within 6 seconds, it automatically triggers a reconnect attempt with progressive backoff (up to 5× the base delay). The UI surfaces distinct states: Connecting, Streaming, Frozen, Retrying, and Offline.
- **Camera Orientation** — The camera feed is displayed with a 180° rotation and horizontal mirror flip applied in the Flutter canvas renderer, correcting for the physical mounting orientation of the OV3660 on the car chassis.

---

## 5. Components

### Hardware

| Component | Model / Spec | Notes |
|---|---|---|
| Microcontroller + Camera | ESP32-CAM (AI Thinker) with OV3660 | External SMA antenna version for improved Wi-Fi range |
| Motor Driver | Integrated L298N (kit-specific board) | Compact version; functionally equivalent to standalone L298N module |
| Motors | 4× TT DC Geared Motors | Mounted in metal brackets on acrylic chassis |
| Wheels | 4× rubber wheels | Included with kit |
| Battery | 2× Panasonic NCR18650B 3400mAh | Exceeds 60-minute runtime target |
| Battery Holder | Dual 18650 holder with switch | Mounted on chassis underside |
| Programmer | CH340-based undercarrier board | Plug-and-play USB-C; no manual BOOT pin required for most operations |
| Jumper Wires | 40-pin M-F and M-M 20cm sets | Used for motor driver to ESP32-CAM 6-pin cable |
| Breadboard | 830-point solderless | Available for prototyping; not in active use on final build |

> **Note:** The HC-SR04 ultrasonic sensor was removed from the final build. Although the sensor and mounting bracket were procured, the team decided to exclude it from the final hardware configuration.

### Software & Firmware

| Layer | Technology | Purpose |
|---|---|---|
| Firmware | Arduino IDE 2.3.8 + ESP32 Core 3.3.8 | Flashing and compiling ESP32-CAM firmware |
| Firmware Language | C++ (Arduino framework) | `ESP32CAM_Car.ino` and `app_httpd.cpp` |
| Board Package | esp32 by Espressif Systems | Board: AI Thinker ESP32-CAM |
| USB Driver | CH340 (WCH CH341SER) | Required for Windows COM port recognition |
| Mobile App | Flutter (Android) | Rover control, CV overlays, stream management |
| ML Library | Google ML Kit (`google_mlkit_object_detection`) | On-device object detection inference |
| State Management | flutter_bloc / Cubit | `RoverControlCubit`, `ConnectionCubit`, `MlSettingsCubit` |
| Navigation | go_router | Screen routing between Connection, Control, and ML Settings |
| DI | get_it + injectable | Dependency injection across the Flutter app |

### Pin Mapping (ESP32-CAM ↔ Motor Driver)

| Motor Driver Socket | ESP32-CAM Pin | Function |
|---|---|---|
| EN_B | GPIO 12 | Motor B enable (must be HIGH) |
| 4 | GPIO 13 | Right Backward |
| 3 | GPIO 14 | Right Forward |
| 2 | GPIO 15 | Left Backward |
| 1 | GPIO 33 | Left Forward |
| EN_A | GPIO 2 | Motor A enable (must be HIGH) |
| 5V | 5V | Power from motor driver to ESP32-CAM |
| GND | GND | Common ground |

---

## 6. Architecture

The ESP32-CAM runs a dual-server setup: Port 80 serves the Flutter Android app and handles HTTP GET motor commands sent by the Flutter client, while Port 81 runs a dedicated MJPEG camera stream server for real-time video.

```
┌─────────────────────────────────────────────────────────┐
│                  Flutter Android App                     │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │
│  │  Connection  │  │Rover Control │  │  ML Settings  │ │
│  │    Screen    │  │    Screen    │  │    Screen     │ │
│  │              │  │              │  │               │ │
│  │ Auto-scan    │  │ D-pad        │  │ Object Detect │ │
│  │ subnet       │  │ LED toggle   │  │ Mode select   │ │
│  │ Fingerprint  │  │ Stream view  │  │ Confidence    │ │
│  │ rover IP     │  │ CV overlays  │  │ threshold     │ │
│  └──────┬───────┘  └──────┬───────┘  └───────────────┘ │
│         │                 │                             │
│  ConnectionCubit   RoverControlCubit   MlSettingsCubit  │
└─────────┼───────────────┬─┴─────────────────────────────┘
          │               │
          │  Mobile Hotspot (ROVER-CAR / rover1234)
          │               │
          ▼               ▼
┌─────────────────────────────────────────────────────────┐
│                   ESP32-CAM Firmware                     │
│                                                         │
│  ┌──────────────────────┐  ┌──────────────────────────┐ │
│  │   HTTP Server        │  │   MJPEG Stream Server    │ │
│  │   Port 80            │  │   Port 81                │ │
│  │                      │  │                          │ │
│  │ GET /?go=forward     │  │ GET /stream              │ │
│  │ GET /?go=backward    │  │ multipart/x-mixed-replace│ │
│  │ GET /?go=left        │  │ OV3660 · QVGA · quality12│ │
│  │ GET /?go=right       │  │                          │ │
│  │ GET /?go=stop        │  └──────────────────────────┘ │
│  │ GET /?go=ledon       │                               │
│  │ GET /?go=ledoff      │                               │
│  └──────────┬───────────┘                               │
│             │                                           │
│  ┌──────────▼───────────────────────────────────────┐   │
│  │              WheelAct() / GPIO Layer              │   │
│  │  GPIO33(LF) · GPIO15(LB) · GPIO14(RF) · GPIO13(RB)│  │
│  │  GPIO2(EN_A=HIGH) · GPIO12(EN_B=HIGH)             │   │
│  │  GPIO4(LED)                                       │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Data Flow

1. The Flutter app scans the subnet and identifies the rover's IP address via HTTP fingerprinting.
2. The user navigates to the Control screen. The app opens a persistent MJPEG stream connection to `http://<rover_ip>:81/stream`.
3. The app's MJPEG decoder reads the multipart byte stream, extracts individual JPEG frames, and renders them onto a Flutter canvas.
4. Each rendered frame is simultaneously passed to the ML pipeline (object detection via ML Kit) and the motion detection pipeline (frame differencing). Overlays are composited on top.
5. When the user presses a D-pad button, `RoverControlCubit` dispatches an HTTP GET request to `http://<rover_ip>/?go=<direction>` on Port 80.
6. The ESP32's HTTP handler maps the `go` parameter to a `WheelAct()` call, which drives the four motor GPIO pins accordingly.
7. When the button is released, a `?go=stop` request is immediately sent.

### Known Issues & Applied Fixes

| Issue | Fix Applied |
|---|---|
| Motors not moving | EN_A (GPIO2) and EN_B (GPIO12) must be set `HIGH` in `setup()` |
| Forward/Backward reversed | Motor connectors P4/P5 and P12/P13 placed on correct same-side channels |
| Left/Right swapped | Swapped `gpLf`/`gpLb` and `gpRf`/`gpRb` pin assignments in firmware |
| Camera feed inverted | Applied `rotate(180deg)` via CSS transform in original web UI; mirrored in Flutter canvas |
| Camera feed mirrored | Applied `scaleX(-1)` transform; corrected in Flutter canvas renderer |
| Button too sensitive (web UI) | 150ms `setTimeout` debounce added to `startPress()` in original web UI |
| Camera lag / freeze | Framesize set to `FRAMESIZE_QVGA`; quality set to `12` |
| Stream disconnects | Flutter stream watchdog with 6-second timeout and progressive backoff reconnect |
| IP address changes on reboot | Auto-discovery in Flutter app scans subnet on each connection attempt |

---

## 7. Setup & Installation

### A. Flashing the ESP32-CAM Firmware

**Prerequisites:**
- Arduino IDE 2.3.8 or later
- ESP32 board package by Espressif Systems, version 3.3.8 (install via Boards Manager)
- CH340 USB driver: https://www.wch-ic.com/downloads/CH341SER_EXE.html
- Board selected: **AI Thinker ESP32-CAM**

**Steps:**
1. Place `ESP32CAM_Car.ino`, `app_httpd.cpp`, and `camera_index.h` in the same sketch folder.
2. Open `ESP32CAM_Car.ino` in Arduino IDE.
3. Confirm the SSID and password in the `.ino` file match your hotspot:
   ```cpp
   const char* ssid = "ROVER-CAR";
   const char* password = "rover1234";
   ```
4. Select the correct COM port under **Tools → Port**.
5. Click **Upload**.
6. When `Connecting.....` appears in the console, hold the **BOOT** button on the ESP32-CAM board.
7. Release when the upload percentage begins counting.
8. Wait for **Done uploading**.
9. Press **RESET** on the board.
10. Open **Serial Monitor** at **115200 baud** to confirm the IP address printed after connection.

### B. Setting Up the Flutter App

**Prerequisites:**
- Flutter SDK (stable channel)
- Android device with USB debugging enabled
- Developer Mode enabled on Windows (run `start ms-settings:developers`)

**Steps:**
1. Navigate to the Flutter project directory.
2. Run `flutter pub get` to install dependencies.
3. Connect your Android device via USB.
4. Confirm the device appears with `flutter devices`.
5. Run `flutter run` and select your Android device.
6. The app will build and install on the device.

> **Note:** `google_mlkit_object_detection` is Android-only. The app must run on a physical Android device; emulators do not support ML Kit hardware acceleration.

### C. Wi-Fi Configuration

The rover connects to a mobile hotspot in station (STA) mode — it does not broadcast its own network.

| Setting | Value |
|---|---|
| Hotspot Name (SSID) | `ROVER-CAR` |
| Hotspot Password | `rover1234` |
| ESP32-CAM mode | Station (STA) |
| Command server port | 80 |
| Stream server port | 81 |

Both the Android device running the Flutter app and the rover must be connected to the same `ROVER-CAR` hotspot for the app's auto-discovery and HTTP commands to reach the ESP32-CAM.

---

## 8. Standard Operating Procedure

### Starting the Rover

1. Insert fully charged Panasonic NCR18650B batteries into the holder with correct polarity.
2. On your phone, enable a mobile hotspot with name `ROVER-CAR` and password `rover1234`.
3. Flip the battery switch **ON** on the car chassis.
4. Wait approximately 5 seconds for the ESP32-CAM to boot and connect to the hotspot.
5. Open the Flutter app on your Android device (also connected to the `ROVER-CAR` hotspot).
6. On the Connection screen, tap **Auto Detect Rover**. The app will scan the subnet and connect automatically.
7. The Rover Control screen will load with the live camera feed and D-pad.

### Driving the Rover

- **Forward / Backward / Left / Right** — Hold the corresponding D-pad button. Movement begins after a 150ms debounce. Release to stop.
- **Stop** — Release any direction button, or tap the Stop button directly.
- **LED Flash** — Tap the LED toggle button to turn the onboard flash on or off.

### Using Computer Vision Features

- Navigate to **ML Settings** from the control screen.
- Select an object detection mode: **Off**, **General**, or **Person Only**.
- Adjust the **confidence threshold** and **detection interval** to suit your environment.
- Return to the control screen — ML overlays (bounding boxes and labels) will render on top of the live feed.
- Motion detection runs continuously in the background regardless of ML mode. Orange overlay regions and a red banner will appear when movement is detected.

### Checking the IP Address Manually

If auto-discovery fails, retrieve the IP address manually:
1. Connect the ESP32-CAM to a computer via USB.
2. Open **Serial Monitor** in Arduino IDE at **115200 baud**.
3. Press **RESET** on the board.
4. The IP address will print in the format: `Camera Ready! Use 'http://10.x.x.x' to connect`.
5. Enter that IP manually in the Flutter app's connection screen.

### Stopping the Rover

1. Tap **Stop** in the app before powering down.
2. Flip the battery switch **OFF** on the chassis.
3. Disable the mobile hotspot on your phone.

---

## References

- Viral Science — ESP32-CAM Surveillance Car: https://www.viralsciencecreativity.com/post/esp32-cam-surveillance-spy-camera-car
- Random Nerd Tutorials — ESP32-CAM Car Robot Web Server: https://randomnerdtutorials.com/esp32-cam-car-robot-web-server
- MakerLab Kit Product Page: https://www.makerlab.ph/products/makerlab-esp32-cam-4wd-smart-robot-car-kit-wireless-control
- Google ML Kit Object Detection: https://developers.google.com/ml-kit/vision/object-detection

---

*ROVER Project · ES 130 · BSCS-3A · WMSU Zamboanga City · April 2026*
