import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/services/motion_detection_action_runner.dart';
import '../../data/services/motion_detection_service.dart';
import '../../data/services/motion_snapshot_storage_service.dart';
import '../../domain/entities/motion_detection_settings.dart';
import '../../domain/enums/motion_detection_action_mode.dart';
import '../../../rover_control/domain/entities/rover_command.dart';

part 'motion_detection_state.dart';

typedef MotionCommandSender = Future<void> Function(RoverCommand command);

class MotionDetectionCubit extends Cubit<MotionDetectionState> {
  MotionDetectionCubit({required MotionCommandSender sendCommand})
    : _sendCommand = sendCommand,
      super(const MotionDetectionState());

  final MotionCommandSender _sendCommand;
  final MotionDetectionService _service = MotionDetectionService();
  final MotionDetectionActionRunner _actionRunner =
      MotionDetectionActionRunner();
  final MotionSnapshotStorageService _snapshotStorage =
      MotionSnapshotStorageService();

  MotionDetectionSettings _settings = const MotionDetectionSettings();
  DateTime? _lastDetectionAt;
  DateTime? _lastFrameAt;
  Uint8List? _latestFrame;
  bool _streamHealthy = true;
  bool _lightAndSnapshotRunning = false;

  // ── Public API ──────────────────────────────────────────────────────────

  /// Push updated settings (called whenever MlSettingsCubit emits a new state).
  void updateSettings(MotionDetectionSettings settings) {
    final wasEnabled = _settings.enabled;
    _settings = settings;

    if (!settings.enabled) {
      _actionRunner.stop();
      _service.reset();
      if (!isClosed)
        emit(
          state.copyWith(status: MotionDetectionStatus.idle, enabled: false),
        );
    } else if (!wasEnabled && settings.enabled) {
      _service.reset();
      if (!isClosed)
        emit(
          state.copyWith(
            status: MotionDetectionStatus.monitoring,
            enabled: true,
          ),
        );
    } else {
      if (!isClosed) emit(state.copyWith(enabled: settings.enabled));
    }
  }

  /// Feed a decoded JPEG frame from the stream viewer.
  void updateFrame(Uint8List jpegBytes) {
    if (!_settings.enabled || !_streamHealthy) return;
    _latestFrame = jpegBytes;

    // Throttle: only analyse once per sampleIntervalMs.
    final now = DateTime.now();
    final last = _lastFrameAt;
    if (last != null &&
        now.difference(last).inMilliseconds < _settings.sampleIntervalMs) {
      return;
    }
    _lastFrameAt = now;

    // Cooldown: skip if we just triggered.
    final lastDet = _lastDetectionAt;
    if (lastDet != null &&
        now.difference(lastDet).inMilliseconds < _settings.cooldownMs) {
      return;
    }

    // Do not start a new analysis if action routine is already running.
    if (_actionRunner.isRunning || _lightAndSnapshotRunning) return;

    // Run pixel-diff in the same isolate — the grid is tiny (32×24) so it
    // completes in < 5 ms on any modern device.
    final result = _service.analyse(
      jpegBytes: jpegBytes,
      sensitivity: _settings.sensitivity,
    );

    developer.log(
      'Motion score: ${(result.score * 100).toStringAsFixed(1)}%  '
      'detected: ${result.detected}',
      name: 'MotionDetectionCubit',
    );

    if (!isClosed) {
      emit(
        state.copyWith(
          lastScore: result.score,
          status: result.detected
              ? MotionDetectionStatus.detected
              : MotionDetectionStatus.monitoring,
          enabled: true,
        ),
      );
    }

    if (result.detected) {
      _lastDetectionAt = now;
      _triggerAction();
    }
  }

  /// Notify the cubit when the stream health changes so detection can be
  /// paused while the stream is frozen.
  void notifyStreamHealth(bool healthy) {
    _streamHealthy = healthy;
    if (!healthy) {
      _service.reset();
    }
  }

  @override
  Future<void> close() {
    _actionRunner.stop();
    return super.close();
  }

  // ── Internal ────────────────────────────────────────────────────────────

  void _triggerAction() {
    final mode = _settings.actionMode;

    if (mode == MotionDetectionActionMode.overlayOnly) return;
    if (mode == MotionDetectionActionMode.snapshot) {
      unawaited(_captureSnapshot());
      return;
    }

    if (mode == MotionDetectionActionMode.lightAndSnapshot) {
      unawaited(_runLightThenSnapshot());
      return;
    }

    // Routine-only mode.
    if (!isClosed) {
      emit(
        state.copyWith(status: MotionDetectionStatus.routine, enabled: true),
      );
    }

    unawaited(
      _actionRunner
          .start(
            sendCommand: _sendCommand,
            pulseDuration: Duration(milliseconds: _settings.routinePulseMs),
            cycles: _settings.routineCycles,
            ledOn: _settings.ledOnDuringRoutine,
          )
          .whenComplete(() {
            if (!isClosed) {
              emit(
                state.copyWith(
                  status: MotionDetectionStatus.monitoring,
                  enabled: true,
                ),
              );
            }
          }),
    );
  }

  Future<void> _runLightThenSnapshot() async {
    if (_lightAndSnapshotRunning) return;
    _lightAndSnapshotRunning = true;
    if (!isClosed) {
      emit(
        state.copyWith(status: MotionDetectionStatus.routine, enabled: true),
      );
    }

    try {
      await _sendCommand(RoverCommand.ledOn);
      await Future.delayed(const Duration(milliseconds: 2500));
      await _sendCommand(RoverCommand.ledOff);
      await _captureSnapshot();
    } finally {
      _lightAndSnapshotRunning = false;
      if (!isClosed) {
        emit(
          state.copyWith(
            status: MotionDetectionStatus.monitoring,
            enabled: true,
          ),
        );
      }
    }
  }

  Future<void> _captureSnapshot() async {
    final frame = _latestFrame;
    if (frame == null) {
      developer.log(
        'Snapshot requested but no frame is available yet.',
        name: 'MotionDetectionCubit',
      );
      return;
    }

    try {
      final path = await _snapshotStorage.save(frame);
      developer.log('Snapshot saved to $path', name: 'MotionDetectionCubit');
    } catch (e) {
      developer.log('Snapshot save failed: $e', name: 'MotionDetectionCubit');
    }
  }
}
