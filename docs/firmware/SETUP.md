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

1. If you changed `.ino` or `.cpp`, do firmware upload.
2. If you changed only `index.html`, regenerate `camera_index.h`, then do firmware upload.
3. If you changed both firmware and web UI, regenerate `camera_index.h` first, then upload firmware once.

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

## Regenerate embedded web payload (index.html changes)

1. Compress `firmware/index.html` to gzip.
2. Convert gzip bytes into C array and update `firmware/camera_index.h`.
3. Confirm `index_html_gz_len` matches the payload size.
4. Upload firmware (`ESP32CAM_Car.ino`) normally.

## Fast verification

1. Open rover IP in browser.
2. Confirm UI loads.
3. Confirm stream works on :81/stream.
4. Confirm go/stop and LED on/off work.

## Notes

- Firmware does not auto-read `firmware/index.html` on your PC.
- Board serves the web UI from embedded `camera_index.h` payload.
- Changing `index.html` has no effect until `camera_index.h` is regenerated and firmware is reflashed.
- If embedded payload is unavailable, fallback page is served.
