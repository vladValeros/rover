# Firmware Update Workflow

## Scope

- This guide is for day-to-day updates.
- IDE, board package, and plugin are already installed.
- Device already runs firmware successfully.

## Current file layout

- firmware/ESP32CAM_Car.ino
- firmware/app_httpd.cpp
- firmware/camera_index.h
- firmware/index.html

## Decide what changed

1. If you changed .ino or .cpp, do firmware upload.
2. If you changed only index.html, do SPIFFS upload only.
3. If you changed both, do firmware upload first, then SPIFFS upload.

## Firmware upload (.ino/.cpp)

1. Connect ESP32-CAM to USB-TTL.
2. Set flash mode with GPIO0 to GND.
3. Open firmware/ESP32CAM_Car.ino in Arduino IDE.
4. Select board: AI Thinker ESP32-CAM.
5. Select correct COM port.
6. Click Upload.
7. If upload waits at Connecting, press RESET.
8. After upload, remove GPIO0 from GND.
9. Press RESET to boot normally.
10. Check serial monitor for rover IP.

## SPIFFS upload (index.html only)

1. Ensure data folder exists under sketch directory.
2. Copy firmware/index.html into data/index.html.
3. Run Upload LittleFS/SPIFFS from command palette.
4. Wait until upload complete.
5. Reboot board if page does not refresh immediately.

## Fast verification

1. Open rover IP in browser.
2. Confirm UI loads.
3. Confirm stream works on :81/stream.
4. Confirm go/stop and LED on/off work.

## Notes

- Firmware does not auto-read from firmware/index.html on your PC.
- Board only serves /index.html from SPIFFS partition.
- If SPIFFS upload is skipped, board keeps previous UI.
- If /index.html is missing on SPIFFS, fallback page is served.
