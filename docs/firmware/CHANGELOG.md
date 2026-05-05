# Changelog — firmware

All notable changes to the ESP32-CAM firmware and web UI are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [Unreleased]

### Changed — File layout and docs split

- Moved active UI source from `firmware/web/index.html` to `firmware/index.html` so it sits at the same level as firmware source files.
- Kept SPIFFS runtime behavior unchanged (`/index.html` is still the served path on device).
- Extracted procedural flashing/upload instructions from firmware README into `docs/firmware/SETUP.md`.
- Refocused `docs/firmware/README.md` to architecture and API reference only.

### Added — Web UI separation (SPIFFS)

**Branch:** `nekolaiv/web-sync`

#### `web/index.html` (new file)
- Created a standalone web UI stored on the SPIFFS filesystem, completely separate from the firmware binary.
- Editing this file and re-uploading to SPIFFS does **not** require reflashing the firmware.
- **Layout and features mirror the Flutter mobile app:**
  - Live MJPEG stream rendered on a `<canvas>` element.
  - Camera orientation chips: Normal, Rotate 180, Rotate 180 + Mirror.
  - Motion Pattern AI runtime card with Start/Stop button, step label, and running/ready/disabled state pills — identical to the Flutter control screen card.
  - All four motion patterns supported: Box, Figure-8, L Pattern, Shuttle (Back & Forth).
  - Per-pattern preset timings (same values as Flutter `MotionPatternType.defaultTimings`).
  - D-pad with hold-to-drive behaviour; pressing any direction cancels an active pattern (manual override, same as Flutter).
  - LED on/off controls.
  - ⚙️ Settings screen with full ML controls (Object Detection, Face Detection, Motion Detection, Motion Patterns with sliders).
  - TF.js COCO-SSD object detection and BlazeFace face detection loaded from CDN; graceful "unavailable" message if no internet.
  - Pixel-diff motion detection — works fully offline, no CDN required.
  - Stream freeze watchdog: 6 s threshold, 2 s poll interval — shows offline sheet and stops any active pattern.
  - Auto-stop on browser tab hide (`visibilitychange` event) — mirrors Flutter `didChangeAppLifecycleState`.
  - Snackbar notifications for model load status, preset applied, and connection events.

#### `app_httpd.cpp`
- Added `#include "SPIFFS.h"`.
- Replaced the monolithic string-concatenated `index_handler` with a SPIFFS-first file server:
  - Checks for `/index.html` on SPIFFS; streams it in 512-byte chunks if found.
  - Falls back to a compact built-in minimal page (drive controls + stream) when SPIFFS file is absent.
  - The legacy inline HTML is preserved in-source as a comment reference but is no longer executed.
- All motor, LED, stream, camera, and status handlers are **unchanged**.

#### `ESP32CAM_Car.ino`
- Added `#include "SPIFFS.h"`.
- Added `SPIFFS.begin(true)` in `setup()` before `startCameraServer()`.
  - `true` = auto-format partition on first boot if filesystem is uninitialised.
  - Prints a warning to Serial if mount fails; rover still boots and serves the fallback page.
- No changes to Wi-Fi connection logic, camera init, GPIO pin assignments, or motor enable pins.

---

## Previous changes (pre-changelog)

### Bug fixes applied to `app_httpd.cpp` (recorded retrospectively)

- **Bug 1** — Camera canvas and drive controls were placed after CDN `<script>` tags, blocking interactivity until scripts loaded. Fixed by moving canvas and buttons before CDN includes and using `defer` on script tags.
- **Bug 2** — XHR reuse: a single shared `xhttp` object caused `/go` to be cancelled by the immediately-following `/stop` call. Fixed by creating a new `XMLHttpRequest` per `getsend()` call.
- **Bug 3** — `/capture`, `/status`, and `/control` URI handlers were defined but never registered with `httpd_register_uri_handler`. Fixed by adding the missing registration calls.
- **Bug 4** — Button `startPress`/`endPress` timer was not cleared on `endPress`, causing ghost commands. Fixed by calling `clearTimeout(pressTimer)` in `endPress()`.
