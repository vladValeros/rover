import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../autopilot/domain/entities/autopilot_settings.dart';
import '../../../rover_control/domain/entities/rover_command.dart';
import '../../data/services/depth_estimation_service.dart';

// ── States ────────────────────────────────────────────────────────────────

sealed class AutopilotState {
  const AutopilotState();
}

/// Autopilot is off — rover under manual / pattern control.
final class AutopilotIdle extends AutopilotState {
  const AutopilotIdle();
}

/// Autopilot active, avoid loop running.
final class AutopilotRunning extends AutopilotState {
  const AutopilotRunning();
}

/// Stream freeze or failure detected — rover stopped, waiting for recovery.
final class AutopilotStreamLagged extends AutopilotState {
  const AutopilotStreamLagged();
}

/// Autopilot explicitly stopped by the user.
final class AutopilotStopped extends AutopilotState {
  const AutopilotStopped();
}

// ── Cubit ─────────────────────────────────────────────────────────────────

typedef _SendCommand = Future<void> Function(RoverCommand);

/// Drives an obstacle-avoidance loop using monocular depth estimation.
///
/// Control flow:
///  1. [start] → begins [_tick] loop every [_loopInterval].
///  2. Each tick: estimate centre depth → if blocked, stop + slow-turn until
///     clear, then resume forward.
///  3. [notifyStreamHealth(false)] while [AutopilotRunning] → sends stop,
///     transitions to [AutopilotStreamLagged].
///  4. [notifyStreamHealth(true)] while [AutopilotStreamLagged] → resumes.
///  5. [stop] → cancels loop, sends stop command.
class AutopilotCubit extends Cubit<AutopilotState> {
  AutopilotCubit({required _SendCommand sendCommand})
    : _sendCommand = sendCommand,
      super(const AutopilotIdle());

  final _SendCommand _sendCommand;
  final DepthEstimationService _depth = DepthEstimationService();

  // Live settings — updated by the control screen from MlSettingsCubit.
  AutopilotSettings _settings = const AutopilotSettings();

  Duration get _loopInterval =>
      Duration(milliseconds: _settings.loopIntervalMs);
  Duration get _turnPulse => Duration(milliseconds: _settings.turnPulseMs);
  double get _blockThreshold => _settings.blockThreshold;
  double get _clearThreshold => _settings.clearThreshold;

  Uint8List? _latestFrame;
  bool _streamHealthy = true;
  bool _loopActive = false;
  bool _analysisInFlight = false;
  double? _latestCenterDepth;
  DateTime? _lastDepthAt;
  bool _isBlocked = false;
  bool _isAvoiding = false;
  String _statusText = 'Idle';

  double? get latestCenterDepth => _latestCenterDepth;
  DateTime? get lastDepthAt => _lastDepthAt;
  bool get isBlocked => _isBlocked;
  bool get isAvoiding => _isAvoiding;
  bool get isDepthAvailable => !_depth.isUnavailable;
  String get statusText => _statusText;
  String? get depthError => _depth.lastError;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Push updated settings (called whenever MlSettingsCubit emits).
  void updateSettings(AutopilotSettings settings) {
    _settings = settings;
  }

  /// Feed the latest JPEG frame from the stream viewer.
  void updateFrame(Uint8List frame) {
    _latestFrame = frame;
    _maybeAnalyzePassiveDepth();
  }

  /// Called by the stream viewer when stream health changes.
  void notifyStreamHealth(bool healthy) {
    _streamHealthy = healthy;
    if (!healthy) {
      _loopActive = false;
      _isAvoiding = false;
      _setDiagnostics(
        statusText: 'Stream frozen or disconnected — rover paused',
      );
      if (state is AutopilotRunning) {
        _sendCommandSilently(RoverCommand.stop);
        emit(const AutopilotStreamLagged());
      } else {
        _refreshState();
      }
    } else if (healthy && state is AutopilotStreamLagged) {
      _setDiagnostics(statusText: 'Stream recovered — checking depth');
      emit(const AutopilotRunning());
      _runLoop();
    } else if (healthy && _settings.enabled) {
      _setDiagnostics(statusText: 'Stream recovered — depth ready');
      _refreshState();
      _maybeAnalyzePassiveDepth();
    }
  }

  /// Start the autopilot avoid loop.
  void start() {
    if (state is AutopilotRunning) return;
    _setDiagnostics(
      statusText: _latestFrame == null
          ? 'Waiting for camera frame'
          : 'Autopilot active — checking depth',
    );
    emit(const AutopilotRunning());
    _runLoop();
  }

  /// Stop the autopilot loop and send a stop command to the rover.
  void stop() {
    _loopActive = false;
    _isBlocked = false;
    _isAvoiding = false;
    _statusText = 'Autopilot stopped';
    _sendCommandSilently(RoverCommand.stop);
    emit(const AutopilotStopped());
  }

  @override
  Future<void> close() {
    _loopActive = false;
    _depth.dispose();
    return super.close();
  }

  // ── Loop ─────────────────────────────────────────────────────────────────

  void _runLoop() {
    _loopActive = true;
    _tick();
  }

  Future<void> _tick() async {
    if (!_loopActive || state is! AutopilotRunning || isClosed) return;

    final frame = _latestFrame;
    if (frame == null || !_streamHealthy) {
      if (frame == null) {
        _setDiagnostics(statusText: 'Waiting for camera frame');
        _refreshState();
      }
      Future.delayed(_loopInterval, _tick);
      return;
    }

    // --- Depth check --------------------------------------------------------
    final centerDepth = await _depth.computeCenterDepth(frame);

    if (!_loopActive || state is! AutopilotRunning || isClosed) return;

    if (centerDepth == null) {
      _latestCenterDepth = null;
      _isBlocked = false;
      _isAvoiding = false;
      _statusText = _depthFailureStatus();
      await _sendCommandSilently(RoverCommand.stop);
      _refreshState();
      if (_loopActive && state is AutopilotRunning && !isClosed) {
        Future.delayed(_loopInterval, _tick);
      }
      return;
    }

    _latestCenterDepth = centerDepth;
    _lastDepthAt = DateTime.now();

    final isBlocked = centerDepth > _blockThreshold;
    _isBlocked = isBlocked;
    _isAvoiding = false;

    if (isBlocked) {
      _statusText = 'Obstacle ahead — stopping';
      _refreshState();
      // Stop first, then slowly turn left until path clears.
      await _sendCommandSilently(RoverCommand.stop);
      await _avoidObstacle();
    } else {
      _statusText = 'Path clear — moving forward';
      _refreshState();
      // Path clear — go forward.
      await _sendCommandSilently(RoverCommand.forward);
    }

    if (_loopActive && state is AutopilotRunning && !isClosed) {
      Future.delayed(_loopInterval, _tick);
    }
  }

  /// Slowly turns left in short pulses until the centre depth drops below
  /// [_clearThreshold] (path ahead is clear).
  Future<void> _avoidObstacle() async {
    for (var attempt = 0; attempt < 24; attempt++) {
      if (!_loopActive || state is! AutopilotRunning || isClosed) return;
      if (!_streamHealthy) return;

      _isAvoiding = true;
      _isBlocked = true;
      _statusText = 'Obstacle ahead — turning left';
      _refreshState();
      await _sendCommandSilently(RoverCommand.left);
      await Future<void>.delayed(_turnPulse);
      await _sendCommandSilently(RoverCommand.stop);

      final frame = _latestFrame;
      if (frame == null) continue;

      final depth = await _depth.computeCenterDepth(frame);
      if (depth == null) {
        _latestCenterDepth = null;
        _isBlocked = false;
        _isAvoiding = false;
        _statusText = _depthFailureStatus();
        _refreshState();
        return;
      }

      _latestCenterDepth = depth;
      _lastDepthAt = DateTime.now();
      if (depth < _clearThreshold) {
        _isBlocked = false;
        _isAvoiding = false;
        _statusText = 'Path clear — resuming forward';
        _refreshState();
        return;
      }
    }
    // Gave up after 24 pulses — path will be re-evaluated on next tick.
    _isAvoiding = false;
    _statusText = 'Obstacle still ahead — rechecking';
    _refreshState();
  }

  void _setDiagnostics({required String statusText}) {
    _statusText = statusText;
  }

  void _maybeAnalyzePassiveDepth() {
    final lastDepthAt = _lastDepthAt;
    if (_analysisInFlight ||
        !_settings.enabled ||
        _loopActive ||
        state is AutopilotRunning ||
        state is AutopilotStreamLagged ||
        !_streamHealthy ||
        _latestFrame == null) {
      return;
    }
    if (lastDepthAt != null &&
        DateTime.now().difference(lastDepthAt) < _loopInterval) {
      return;
    }
    unawaited(_analyzePassiveDepth());
  }

  Future<void> _analyzePassiveDepth() async {
    final frame = _latestFrame;
    if (frame == null || isClosed) return;

    _analysisInFlight = true;
    try {
      final centerDepth = await _depth.computeCenterDepth(frame);
      if (isClosed ||
          state is AutopilotRunning ||
          state is AutopilotStreamLagged) {
        return;
      }

      if (centerDepth == null) {
        _latestCenterDepth = null;
        _isBlocked = false;
        _isAvoiding = false;
        _statusText = _depthFailureStatus();
        _refreshState();
        return;
      }

      _latestCenterDepth = centerDepth;
      _lastDepthAt = DateTime.now();
      _isBlocked = centerDepth > _blockThreshold;
      _isAvoiding = false;
      _statusText = _isBlocked
          ? 'Obstacle ahead — autopilot idle'
          : 'Depth ready — autopilot idle';
      _refreshState();
    } finally {
      _analysisInFlight = false;
    }
  }

  String _depthFailureStatus() {
    final details = _depth.lastError;
    final summary = _depth.isUnavailable
        ? 'Depth model unavailable — rover held'
        : 'Depth inference failed — rover held';
    if (details == null || details.isEmpty) {
      return summary;
    }

    final compact = details.length > 120
        ? '${details.substring(0, 117)}...'
        : details;
    return '$summary\n$compact';
  }

  void _refreshState() {
    if (isClosed) return;
    switch (state) {
      case AutopilotIdle():
        emit(const AutopilotIdle());
      case AutopilotRunning():
        emit(const AutopilotRunning());
      case AutopilotStreamLagged():
        emit(const AutopilotStreamLagged());
      case AutopilotStopped():
        emit(const AutopilotStopped());
    }
  }

  Future<void> _sendCommandSilently(RoverCommand cmd) async {
    try {
      await _sendCommand(cmd);
    } catch (_) {
      // Ignore — stream health callbacks will handle connectivity loss.
    }
  }
}
