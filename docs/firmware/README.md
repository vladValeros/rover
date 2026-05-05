# from_arduino — ESP32-CAM Rover Firmware

This folder contains the Arduino firmware for the ESP32-CAM rover, along with the web UI that the rover serves over HTTP.

---

## Hardware

| Component | Details |
|---|---|
| Board | AI Thinker ESP32-CAM |
| Camera | OV2640 (JPEG, MJPEG stream) |
| Motor driver | L298N-compatible (4-pin direction control) |
| LED | GPIO 4 (onboard flash) |

Motor GPIO mapping (current):

| Pin | Role |
|---|---|
| GPIO 33 | Left Forward |
| GPIO 15 | Left Backward |
| GPIO 14 | Right Forward |
| GPIO 13 | Right Backward |
| GPIO 4 | LED / Flash |

---

## Files

| File | Purpose |
|---|---|
| `ESP32CAM_Car.ino` | Entry point — Wi-Fi connection, camera init, SPIFFS mount, server start |
| `app_httpd.cpp` | HTTP server — all endpoint handlers, stream handler, web UI serving logic |
| `camera_index.h` | Legacy: GZIP-compressed inline HTML (kept as reference, no longer active) |
| `web/index.html` | **Active web UI** — edit this file to update the interface without touching firmware |

---

## How it works

The rover connects to a known Wi-Fi network (configured by `ssid`/`password` in `ESP32CAM_Car.ino`). It does **not** run its own hotspot — it joins the network as a client. Once connected, it starts two HTTP servers:

| Server | Port | Purpose |
|---|---|---|
| Control server | 80 | Serves the web UI and accepts command endpoints |
| Stream server | 81 | Serves the live MJPEG camera stream at `/stream` |

Access the rover by navigating to its LAN IP address in a browser (printed to Serial on boot).

---

## HTTP API

These endpoints are used by both the web UI and the Flutter mobile app.

| Endpoint | Method | Action |
|---|---|---|
| `/` | GET | Serves the web UI |
| `/go` | GET | Drive forward |
| `/back` | GET | Drive backward |
| `/left` | GET | Turn left |
| `/right` | GET | Turn right |
| `/stop` | GET | Stop all motors |
| `/ledon` | GET | LED on |
| `/ledoff` | GET | LED off |
| `/capture` | GET | Returns a single JPEG frame |
| `/status` | GET | Returns camera sensor settings as JSON |
| `/control` | GET | Set camera parameters (`?var=...&val=...`) |
| `:81/stream` | GET | MJPEG stream (`multipart/x-mixed-replace`) |

---

## Web UI — SPIFFS separation

The web UI (`web/index.html`) is stored separately from the firmware binary in the ESP32 flash filesystem (SPIFFS). This means:

- **Editing the UI does not require reflashing the firmware.**
- Only the SPIFFS filesystem partition needs to be updated when the web UI changes.

On boot, `index_handler` checks whether `/index.html` exists in SPIFFS. If found, it serves that file. If not found (e.g. first flash before uploading web assets), it falls back to a minimal built-in drive/stream page.

### Uploading the web UI to SPIFFS

1. Install the [Arduino LittleFS/SPIFFS Upload plugin](https://github.com/earlephilhower/arduino-littlefs-upload) for Arduino IDE, or use `esptool`.
2. Place `web/index.html` at the root of your SPIFFS data folder.
3. Upload the filesystem partition — **do not reflash the firmware**.

---

## Web UI features

- Live MJPEG stream with canvas rendering
- Camera orientation modes (Normal / Rotate 180 / Rotate 180 + Mirror)
- Manual drive D-pad with hold-to-drive behaviour
- LED toggle
- Motion Pattern AI (Box, Figure-8, L Pattern, Shuttle) with runtime start/stop
- ML Settings screen: Object Detection, Face Detection, Motion Detection, Motion Patterns with per-pattern preset timings
- TF.js-based object detection (COCO-SSD) and face detection (BlazeFace) loaded from CDN — degrades gracefully with no internet
- Pixel-diff motion detection (no CDN required, fully offline)
- Stream freeze watchdog with offline sheet
- Auto-stop on tab hide (mirrors Flutter app lifecycle behaviour)

---

## Flashing and uploading

### One-time setup (per machine)

1. Install **Arduino IDE** (2.x recommended).
2. Add ESP32 board support — go to **File → Preferences** and paste the following URL into *Additional boards manager URLs*:
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Go to **Tools → Board → Boards Manager**, search `esp32`, and install **esp32 by Espressif Systems**.
4. Install the **LittleFS upload plugin** for web UI uploads (see below).

---

### Uploading firmware (when `.ino` or `.cpp` changes)

> Required when motor logic, HTTP handlers, camera config, or SPIFFS init changes.

1. Wire the ESP32-CAM to a **USB-to-TTL adapter** (the board has no built-in USB):
   - `TX` → `RX` of adapter, `RX` → `TX`, `GND` → `GND`, `5V` → `5V`
   - **GPIO 0 → GND** to put the board into flash mode
2. Open `ESP32CAM_Car/ESP32CAM_Car.ino` in Arduino IDE.
3. Set board: **Tools → Board → ESP32 Arduino → AI Thinker ESP32-CAM**
4. Select the correct port: **Tools → Port**
5. Click **Upload** (▶).
6. When *Connecting...* appears in the console, press the **RESET button** on the board.
7. After upload completes, **disconnect GPIO 0 from GND** and press RESET again to boot normally.

---

### Uploading the web UI to SPIFFS (when `web/index.html` changes)

> Firmware is **not** reflashed — only the filesystem partition is updated.

1. Install the plugin: download the latest `.vsix` from [arduino-littlefs-upload releases](https://github.com/earlephilhower/arduino-littlefs-upload/releases) and drag it into Arduino IDE.
2. Create a folder named `data/` inside the sketch folder (`ESP32CAM_Car/data/`).
3. Copy `web/index.html` into `data/` as `index.html`.
4. In Arduino IDE: **Ctrl+Shift+P** → *Upload LittleFS to Pico/ESP8266/ESP32*.

---

### What requires each upload type

| Change made | Action needed |
|---|---|
| `.ino` or `.cpp` modified | Firmware upload (full flash) |
| `web/index.html` modified | SPIFFS upload only |
| Both changed | Both uploads, firmware first |

---

## Relationship to Flutter mobile app

The Flutter app (`lib/`) and the web UI (`web/index.html`) are independent clients that both talk to the same rover HTTP API. They share no code but are designed to offer equivalent features and a consistent layout. Changes to one do not require changes to the other.

See the project root `README.md` for the full multi-platform overview.
