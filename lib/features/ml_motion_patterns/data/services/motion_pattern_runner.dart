import 'dart:async';

import '../../domain/entities/motion_pattern_settings.dart';
import '../../domain/enums/motion_pattern_type.dart';
import '../../../rover_control/domain/entities/rover_command.dart';

typedef MotionCommandSender = Future<void> Function(RoverCommand command);

typedef MotionStepCallback = void Function(String stepLabel);

class MotionPatternRunner {
  int _runToken = 0;
  bool _isRunning = false;

  bool get isRunning => _isRunning;

  Future<void> start({
    required MotionPatternSettings settings,
    required MotionCommandSender sendCommand,
    MotionStepCallback? onStep,
  }) async {
    if (_isRunning) return;

    final runToken = ++_runToken;
    _isRunning = true;

    try {
      while (_isActive(runToken)) {
        final steps = _buildSteps(settings);
        for (final step in steps) {
          if (!_isActive(runToken)) break;

          onStep?.call(step.label);
          await sendCommand(step.command);
          await _waitCancelable(Duration(milliseconds: step.holdMs), runToken);

          if (!_isActive(runToken)) break;
          await sendCommand(RoverCommand.stop);

          if (settings.interStepPauseMs > 0) {
            await _waitCancelable(
              Duration(milliseconds: settings.interStepPauseMs),
              runToken,
            );
          }
        }
      }
    } finally {
      if (_runToken == runToken) {
        _isRunning = false;
      }
    }
  }

  void stop() {
    if (!_isRunning) return;
    _runToken++;
    _isRunning = false;
  }

  bool _isActive(int token) => _isRunning && _runToken == token;

  Future<void> _waitCancelable(Duration duration, int token) async {
    final deadline = DateTime.now().add(duration);
    while (_isActive(token)) {
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) return;
      final slice = remaining > const Duration(milliseconds: 80)
          ? const Duration(milliseconds: 80)
          : remaining;
      await Future.delayed(slice);
    }
  }

  List<_PatternStep> _buildSteps(MotionPatternSettings settings) {
    switch (settings.pattern) {
      case MotionPatternType.box:
        return [
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
        ];
      case MotionPatternType.figureEight:
        return [
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Left 90', RoverCommand.left, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Left 90', RoverCommand.left, settings.turn90Ms),
        ];
      case MotionPatternType.lPattern:
        return [
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Left 90', RoverCommand.left, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Left 180', RoverCommand.left, settings.turn180Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn Right 90', RoverCommand.right, settings.turn90Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep(
            'Turn Right 180',
            RoverCommand.right,
            settings.turn180Ms,
          ),
        ];
      case MotionPatternType.shuttle:
        return [
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn 180°', RoverCommand.right, settings.turn180Ms),
          _PatternStep('Forward', RoverCommand.forward, settings.forwardMs),
          _PatternStep('Turn 180°', RoverCommand.right, settings.turn180Ms),
        ];
    }
  }
}

class _PatternStep {
  const _PatternStep(this.label, this.command, this.holdMs);

  final String label;
  final RoverCommand command;
  final int holdMs;
}
