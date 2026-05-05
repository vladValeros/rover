# firmware — ESP32-CAM Rover Firmware

This document explains the firmware module structure and runtime behavior.

For step-by-step update/upload workflow, use `docs/firmware/SETUP.md`.

## Hardware

- Board: AI Thinker ESP32-CAM
- Camera: OV2640 (JPEG, MJPEG stream)
- Motor driver: L298N-compatible (4-pin direction control)
- LED: GPIO 4 (onboard flash)

Motor GPIO mapping:

- GPIO 33: Left Forward
- GPIO 15: Left Backward
- GPIO 14: Right Forward
- GPIO 13: Right Backward
- GPIO 4: LED / Flash

## Source files

- `firmware/ESP32CAM_Car.ino`: Entry point, Wi-Fi, camera init, SPIFFS mount, starts web/stream servers
- `firmware/app_httpd.cpp`: HTTP handlers, control endpoints, stream endpoint
- `firmware/camera_index.h`: Legacy inline web payload (reference only)
- `firmware/index.html`: Active web UI source that is uploaded to SPIFFS as `/index.html`

## Network model

- Rover joins a known Wi-Fi network as a client (SSID/password in `.ino`)
- Device and rover are on the same LAN
- Access rover at the LAN IP shown in serial logs

## Runtime services

- Port 80: Control server and UI page (`/`)
- Port 81: MJPEG stream (`/stream`)

## HTTP API

- `GET /`: serves web UI
- `GET /go`, `/back`, `/left`, `/right`, `/stop`: motor control
- `GET /ledon`, `/ledoff`: light control
- `GET /capture`: single JPEG frame
- `GET /status`: camera sensor settings JSON
- `GET /control?var=...&val=...`: camera parameter update
- `GET :81/stream`: MJPEG stream

## SPIFFS separation

- UI changes do not require firmware reflashing
- `index_handler` serves `/index.html` from SPIFFS when available
- If `/index.html` is missing, firmware serves a minimal built-in fallback control page

## Web UI scope

- Stream rendering
- Directional controls and LED controls
- Motion pattern runtime controls
- Motion, face, and object detection controls
- Connection freeze watchdog and safety stop hooks

## Flutter relationship

- Flutter mobile app and firmware web UI are independent clients
- Both call the same rover HTTP API
- Feature layout is aligned, implementation is separate
