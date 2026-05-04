# Rover Control Project Handover (AI-Ready)

## 1. Project Identity

Project name: rover_controll

Project type:
- Flutter application for controlling an ESP32-CAM rover over Wi-Fi
- Companion firmware/web control references in docs folder

Primary goals:
1. Connect to rover by IP (manual or auto-detect)
2. Control movement and LED/flash
3. View MJPEG stream from ESP32-CAM
4. Run optional on-device ML object detection on camera frames
5. Keep ML isolated so new ML features can be added without destabilizing core controls

## 2. Current Implementation Scope

Implemented features:
1. Connection feature
- Manual IP input
- Auto detect rover IP in subnet
- Connection test and save

2. Rover control feature
- Movement commands (forward/back/left/right/stop)
- LED ON/OFF commands
- Improved command failure logging
- LED intent persistence and keep-alive logic

3. Stream viewing feature
- MJPEG parsing from /stream endpoint
- Stream watchdog and freeze detection
- Auto reconnect with progressive backoff
- Offline/retrying/frozen user-friendly states

4. ML settings feature
- Isolated ML settings screen
- Object detection mode and tuning controls
- Local persistence via SharedPreferences

5. ML inference integration
- Optional object detection overlay over stream
- Supports off/general/person/vehicle filters
- Platform guard for unsupported runtimes

6. Routing and dependency injection
- go_router for feature routes
- get_it + injectable for DI wiring

## 3. Tech Stack

Language/runtime:
- Dart SDK ^3.9.2
- Flutter

State management:
- flutter_bloc

Dependency injection:
- get_it
- injectable

Networking:
- dio

Persistence:
- shared_preferences

ML:
- google_mlkit_object_detection
- image

Navigation:
- go_router

Codegen:
- freezed
- json_serializable
- build_runner

## 4. High-Level Architecture

Architecture style:
- Feature-first organization
- Per-feature layering (presentation/domain/data where applicable)
- Cubit-driven UI state

Top-level app flow:
1. main initializes DI
2. RoverApp provides ConnectionCubit and MlSettingsCubit globally
3. Router opens connection screen first
4. On success, rover control screen handles stream + commands
5. ML settings route allows isolated ML configuration

Core folders:
- lib/app: app bootstrap, router, locator
- lib/core: constants, networking, theme, shared utilities/errors
- lib/features/connection: rover address discovery, save/load, test
- lib/features/rover_control: command dispatch, stream viewer, control UI
- lib/features/ml_settings: ML registry, settings persistence, and settings host UI
- lib/features/ml_object_detection: object detection ML module (domain/data/presentation)
- docs: firmware/web reference files

## 5. Important File Map (Navigation Guide)

Entry and app shell:
- lib/main.dart
- lib/app/app.dart
- lib/app/app_router.dart
- lib/app/locator.dart
- lib/app/locator.config.dart

Connection feature:
- lib/features/connection/presentation/screens/connection_screen.dart
- lib/features/connection/presentation/controllers/connection_cubit.dart
- lib/features/connection/data/datasources/connection_remote_datasource.dart
- lib/features/connection/data/datasources/connection_local_datasource.dart

Rover control feature:
- lib/features/rover_control/presentation/screens/rover_control_screen.dart
- lib/features/rover_control/presentation/widgets/rover_stream_viewer_widget.dart
- lib/features/rover_control/presentation/controllers/rover_control_cubit.dart
- lib/features/rover_control/data/datasources/rover_remote_datasource.dart
- lib/features/rover_control/domain/entities/rover_command.dart

ML settings and runtime-isolated ML:
- lib/features/ml_settings/presentation/screens/ml_settings_screen.dart
- lib/features/ml_settings/presentation/controllers/ml_settings_cubit.dart
- lib/features/ml_settings/data/datasources/ml_settings_local_datasource.dart
- lib/features/ml_settings/domain/entities/ml_settings_entity.dart
- lib/features/ml_settings/presentation/registry/ml_feature_registry.dart
- lib/features/ml_object_detection/domain/enums/object_detection_mode.dart
- lib/features/ml_object_detection/domain/entities/object_detection_settings.dart
- lib/features/ml_object_detection/data/services/object_detection_service.dart
- lib/features/ml_object_detection/presentation/widgets/object_detection_settings_card.dart

Firmware/web reference:
- docs/ESP32CAM_Car.ino
- docs/app_httpd.cpp
- docs/camera_index.h

## 6. Data and Control Flows

### 6.1 Connection flow
1. User enters IP or runs auto-detect
2. ConnectionCubit calls use cases
3. Remote datasource probes rover endpoint
4. On success, DioClient base URL is updated
5. Router navigates to rover control

### 6.2 Command flow
1. UI button dispatches RoverCommand
2. RoverControlCubit executes SendRoverCommandUseCase
3. Repository delegates to RoverRemoteDatasource
4. Dio performs GET /go, /stop, /ledon, etc.
5. Failures are surfaced to UI and logged

### 6.3 Stream flow
1. RoverStreamViewerWidget builds stream URI from base URL
2. Dedicated Dio stream client opens /stream on port 81
3. Byte buffer scans JPEG SOI/EOI markers
4. Decoded frame is rendered
5. Watchdog marks frozen stream if frame stalls
6. Reconnect scheduler retries with backoff
7. Offline state shown after threshold failures

### 6.4 ML flow
1. MlSettingsCubit provides object detection settings
2. Stream widget samples frames based on configured interval
3. ObjectDetectionService (inside ml_settings feature) runs MLKit detector
4. Results are mapped to normalized overlays
5. Labels filtered by selected mode (off/general/person/vehicle)

## 7. Why It Is Implemented This Way

Design intent:
1. Keep rover control responsive even when ML is enabled
2. Keep ML optional and disable-able at runtime
3. Isolate configuration and persistence of ML features
4. Gracefully degrade when stream/network/ML plugin fails

Tradeoffs:
1. ML runs on received frames, not firmware-side inference
- Faster iteration on app side
- No firmware model deployment complexity

2. Stream parser is custom MJPEG byte parser
- Works directly with ESP32-CAM stream
- Requires careful reconnect and freeze handling

3. Settings are local-first
- Fast and offline-friendly
- No backend dependency

## 8. ML Isolation Verification (Important)

Question: can a teammate add specific ML without touching unrelated app features?

Answer: Yes, with the new registry contract this is now the intended extension model.

What is now isolated:
1. ML settings state and persistence are isolated in ml_settings feature
2. Object detection is isolated as its own feature module under ml_object_detection
3. Rover control consumes ML outputs/settings but does not own ML internals
4. Settings UI discovers ML features via a registration contract in ml_feature_registry

Current integration boundary:
- rover_stream_viewer_widget is the only intentional integration point that combines stream frame input with ML output overlays

Implication for new ML contributors:
- They should create a new lib/features/ml_<feature>/ module
- They should register the new feature once in ml_feature_registry
- They should only touch rover_control when attaching new overlay outputs or runtime toggles

## 9. How To Contribute: Machine Learning (Flutter App)

Recommended contribution standard:
1. Create new feature folder lib/features/ml_<feature>/ with domain/data/presentation
2. Add feature-specific settings model(s) under that feature module
3. Extend MlSettingsEntity and MlSettingsLocalDatasource to store the feature settings
4. Add/update cubit methods for new settings updates
5. Add feature settings card widget under the new feature module
6. Register it in ml_feature_registry (single registration entry)
7. Integrate into stream widget with strict boundary:
- input: frame bytes
- output: normalized overlays or events
- no command-layer side effects

Rules for isolation:
1. Do not place new ML services under rover_control feature
2. Every ML capability must live in its own ml_<feature> folder
3. Register new ML features through ml_feature_registry only
4. Do not mix command networking logic with ML inference logic
5. Keep feature flags and defaults in MlSettingsEntity
6. Provide graceful fallback if plugin/model unavailable

Performance guidance:
1. Keep inference interval configurable
2. Skip inferences when previous inference still running
3. Filter small/low-confidence detections
4. Avoid blocking UI thread

## 10. How To Contribute: General Features

General standards:
1. Follow existing feature-first folder structure
2. Use Cubit for presentation state transitions
3. Use use case + repository + datasource path for side effects
4. Keep Dio usage inside data layer
5. Add user-friendly failure messages and logs

When adding new rover commands:
1. Add command enum entry in rover_command.dart
2. Add endpoint mapping
3. Expose control in UI widget
4. Keep command dispatch via RoverControlCubit

When adding new routes:
1. Add feature routes file
2. Register in app_router.dart

## 11. Web/Firmware ML Isolation Guidance (for C++ teammate)

Current firmware/web references are in docs and use ESP32 HTTP handlers.

Isolation principle for web-side ML work:
1. Keep rover control handlers stable:
- /go /back /left /right /stop /ledon /ledoff /stream
2. Implement web ML as separate module/process layer that consumes stream frames
3. Do not embed ML changes directly into motor/LED endpoint handlers unless required
4. Keep inference output-to-action mapping behind feature toggles

Recommended structure (conceptual for C++/web teammate):
1. Stream acquisition module
2. Inference module
3. Overlay/decision module
4. Control bridge module

This avoids coupling ML experiments to core rover command reliability.

## 12. Known Constraints and Risks

1. ESP32-CAM power stability can cause LED-off + stream restart loops
2. Heavy camera/LED load may trigger brownout/reboot behavior
3. main.dart still contains Flutter template classes not used by RoverApp
4. Object detection currently targets mobile platforms only

## 13. Operational Commands

Typical local commands:
1. flutter pub get
2. dart analyze lib
3. flutter test
4. flutter run

If DI/model annotations change:
1. dart run build_runner build --delete-conflicting-outputs

## 14. Consistency Standards For AI Contributors

AI contributor checklist:
1. Keep changes scoped to the relevant feature folder
2. Avoid cross-feature imports unless integration boundary requires it
3. Preserve existing routes and state flows
4. Keep user-facing failures actionable and non-technical where possible
5. Add logs for network/stream failures with context
6. Run analyzer/tests after non-trivial changes
7. Do not remove existing behavior silently; document rationale

Documentation standard:
1. Update this handover doc when architecture or boundaries change
2. Include file map and migration notes for major refactors

## 15. Implemented vs Planned Snapshot

Implemented now:
1. Connection management and rover control commands
2. Stream watchdog/offline recovery UX
3. ML settings feature and object detection integration
4. ML service isolation under ml_settings feature
5. LED resilience logic (intent reapply and keep-alive)

Planned/possible next:
1. Additional ML feature cards and services (motion/line/face)
2. Shared ML runtime interface to support multiple detector backends
3. Firmware-side stream load optimization profile for stability
4. Brownout/reboot diagnostics surfaced in app UX
5. Remove unused Flutter template classes from main.dart

## 16. Suggested Next Steps

1. Create a generic ML runtime contract and registry under ml_settings to plug multiple models cleanly.
2. Add per-feature ML isolation tests (settings persistence + inference gate behavior).
3. Add contribution templates for new feature modules and new ML cards.
4. Align firmware and app docs with a single endpoint contract table.
5. Add a troubleshooting section linking power/brownout symptoms to known mitigations.
