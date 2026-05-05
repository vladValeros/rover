# Rover App Machine Learning Plan

## 1) Goal
Build a practical and reliable machine learning pipeline on top of the existing rover camera stream so the user can:

- choose a detection mode at runtime,
- detect specific object categories (for example person only),
- switch to general object detection,
- keep rover control responsive while ML runs.

This plan keeps firmware unchanged. Inference runs on the phone from streamed camera frames.

---

## 2) Current Starting Point
The app already has:

- working MJPEG stream from rover (`/stream` on port 81),
- frame extraction in Flutter (`Uint8List` JPEG frames),
- rover movement/LED control,
- connection management with manual and auto-detect options.

This is enough to add on-device inference without redesigning the whole app.

---

## 3) Recommended Technical Baseline
Primary stack (recommended):

- `tflite_flutter` for TensorFlow Lite inference,
- optional `image` package for preprocessing,
- model assets bundled in app (`.tflite`, labels file).

Why this baseline:

- reliable and mature for mobile inference,
- allows multiple models and mode switching,
- works with the current frame-byte pipeline,
- better long-term flexibility than single-purpose detector plugins.

---

## 4) User-Facing Detection Modes
Initial mode set:

1. `Off` (stream only)
2. `General Detection` (multi-class)
3. `Person Only`
4. `Vehicle Only` (optional initial)

Future mode set:

1. `Custom Class Set` (user-defined filters)
2. `Custom Model` (swap model file)

---

## 5) Architecture Plan (Feature-First + BLoC)
### Domain layer
Define a detector contract that returns structured detection results:

- bounding box,
- class label,
- confidence,
- inference time.

### Data layer
Implement detector adapters:

- TFLite general detector,
- filtered detector wrappers (person-only, vehicle-only).

### Presentation layer
Extend rover control state:

- selected ML mode,
- detector status (loading/running/error),
- latest detection list,
- optional FPS and latency metrics.

UI additions:

- mode selector,
- threshold slider (optional),
- overlay rendering on stream.

---

## 6) Performance and Reliability Rules
To avoid control lag and app freeze:

1. Run inference on sampled frames only (not every frame).
2. Start with 1 to 5 inference FPS.
3. Resize frames to model input dimensions before inference.
4. Run inference off UI thread.
5. If inference fails, auto-fallback to stream-only mode.

Success criteria:

- controls remain responsive,
- stream remains visible,
- mode switching works without reconnecting rover.

---

## 7) Implementation Phases
### Phase 1: Foundation
- Add model runner abstraction.
- Add one general object detection model.
- Show overlay boxes and labels.
- Add `Off` and `General` modes.

### Phase 2: Selectable Presets
- Add class filtering (`Person Only`, `Vehicle Only`).
- Add persisted selected mode.
- Add detector status indicator in UI.

### Phase 3: Robustness
- Add explicit error states and user messages.
- Add safe fallback to stream-only.
- Add simple runtime telemetry (inference ms, detection count).

### Phase 4: Expansion
- Add model registry (multiple models).
- Add advanced modes (tracking, anomaly events, etc.).

---

## 8) Suggested Timeline
- Day 1-2: Phase 1 baseline inference + overlay.
- Day 3: Phase 2 mode switching + filtering.
- Day 4: Phase 3 reliability and fallback.
- Day 5+: Phase 4 optional advanced modes.

---

## 9) Beyond Object Detection (Recommended Next ML)
Good next ML options for rover use cases:

1. `QR/AprilTag Navigation` (high practical value, low compute)
2. `Line/Lane Following Assist`
3. `Person Tracking` (follow mode)
4. `Gesture Command Recognition`
5. `Anomaly/Event Detection` for surveillance alerts

Best next step after object detection:

- QR/AprilTag navigation, because it is deterministic, useful, and efficient on mobile.

---

## 10) Risks and Mitigations
Risk: low-end phone performance
- Mitigation: lower inference FPS and input resolution.

Risk: model load failures
- Mitigation: fallback to stream-only with clear UI message.

Risk: false positives
- Mitigation: confidence threshold and class filtering.

Risk: UI complexity
- Mitigation: start with simple mode selector and add advanced controls later.

---

## 11) Definition of Done
ML feature is considered done when:

1. User can select mode in the app.
2. Overlay updates live on stream.
3. Rover controls remain responsive.
4. Errors degrade gracefully to stream-only mode.
5. Basic tests pass for parsing/filtering/state transitions.
