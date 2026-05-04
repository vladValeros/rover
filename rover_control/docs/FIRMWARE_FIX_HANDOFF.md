# Firmware Handoff: LED Turns Off and Stream Restarts

## 1. Issue Summary

Observed behavior:
1. Light turns ON successfully.
2. After a few to several seconds, stream freezes.
3. Light turns OFF.
4. Stream reconnects or restarts, usually with light OFF.
5. This reproduces on both mobile app and web control page.

Why this matters:
- Since the same behavior appears in web and app, this is unlikely to be app-only logic.

## 2. Critical Review of Logs

Android logs like:
- TransportRuntime SQLiteEventStore
- FIREBASE_ML_SDK
- JobInfoScheduler already scheduled

Interpretation:
- These are background telemetry or ML logging from Android runtime.
- They are not direct evidence of LED OFF command execution or ESP32 camera reboot root cause.

## 3. Firmware Evidence From Current Code

LED behavior in firmware:
1. LED ON only in ledon handler:
   - docs/app_httpd.cpp
2. LED OFF only in ledoff handler:
   - docs/app_httpd.cpp
3. LED starts LOW at boot init:
   - docs/ESP32CAM_Car.ino

Implication:
- If LED goes OFF without explicit OFF command and stream also restarts, reboot or brownout is strongly suspected.

## 4. Most Likely Root Cause (Ranked)

1. Power integrity or brownout under combined LED flash plus camera stream load.
2. Firmware camera settings increase load and current draw enough to destabilize supply.
3. Less likely: firmware logic or watchdog path causing periodic reset under stress.

## 5. Firmware-Side Checks and Changes

Inspect and tune camera load parameters in docs/ESP32CAM_Car.ino.

Recommended initial test profile:
1. Lower frame size.
2. Increase jpeg_quality value slightly to reduce encoding load.
3. Use lower fb_count if memory or stability issues appear.
4. Keep LED endpoint behavior unchanged initially to isolate root cause.

## 6. Hardware Validation Steps

1. Use stable 5V supply with enough current headroom.
2. Test with motors disconnected first.
3. Ensure common ground and short, adequate power wiring.
4. Repeat LED ON plus stream test for at least 2 to 3 minutes.

## 7. Acceptance Criteria

1. LED remains ON continuously during live stream for at least 2 to 3 minutes.
2. No freeze plus reconnect loop.
3. No reboot or brownout signs in serial logs during test window.
4. Same stable result in both web and app clients.

## 8. App-Side Note

App resilience has already been improved:
1. LED intent reapply after reconnect.
2. LED keep-alive attempts while user intent is ON.

These help recovery, but they do not replace firmware or power root-cause fixes.
