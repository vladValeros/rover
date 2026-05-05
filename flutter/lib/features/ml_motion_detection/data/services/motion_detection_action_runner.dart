import 'dart:async';

import '../../../rover_control/domain/entities/rover_command.dart';

typedef ActionCommandSender = Future<void> Function(RoverCommand command);

/// Executes a non-blocking left-right-left-right alert routine when motion is
/// detected, optionally toggling the rover LED during the routine.
class MotionDetectionActionRunner {
  int _token = 0;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  /// Starts the alert routine.
  ///
  /// The routine sends alternating [left]/[right] commands each lasting
  /// [pulseDuration], repeating [cycles] times, then sends [stop].
  /// If [ledOn] is true the LED is switched on before the routine and off
  /// after.  The method completes when the routine finishes or is stopped.
  Future<void> start({
    required ActionCommandSender sendCommand,
    required Duration pulseDuration,
    required int cycles,
    required bool ledOn,
  }) async {
    if (_isRunning) return;

    final token = ++_token;
    _isRunning = true;

    try {
      if (ledOn) {
        await sendCommand(RoverCommand.ledOn);
        if (!_active(token)) return;
      }

      for (int i = 0; i < cycles; i++) {
        if (!_active(token)) break;
        await sendCommand(RoverCommand.left);
        await _wait(pulseDuration, token);

        if (!_active(token)) break;
        await sendCommand(RoverCommand.stop);
        await _wait(const Duration(milliseconds: 60), token);

        if (!_active(token)) break;
        await sendCommand(RoverCommand.right);
        await _wait(pulseDuration, token);

        if (!_active(token)) break;
        await sendCommand(RoverCommand.stop);
        if (i < cycles - 1) {
          await _wait(const Duration(milliseconds: 60), token);
        }
      }

      if (_active(token)) {
        await sendCommand(RoverCommand.stop);
      }
    } finally {
      if (_token == token) {
        _isRunning = false;
        if (ledOn) {
          await sendCommand(RoverCommand.ledOff);
        }
      }
    }
  }

  void stop() {
    if (!_isRunning) return;
    _token++;
    _isRunning = false;
  }

  bool _active(int token) => _isRunning && _token == token;

  Future<void> _wait(Duration duration, int token) async {
    final deadline = DateTime.now().add(duration);
    while (_active(token)) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) return;
      final slice = remaining > const Duration(milliseconds: 60)
          ? const Duration(milliseconds: 60)
          : remaining;
      await Future.delayed(slice);
    }
  }
}
