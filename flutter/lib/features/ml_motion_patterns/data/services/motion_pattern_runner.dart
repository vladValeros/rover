import 'dart:async';

import '../../domain/entities/motion_pattern_definition.dart';
import '../../domain/entities/motion_pattern_settings.dart';
import '../../domain/entities/motion_pattern_step.dart';
import '../../domain/enums/motion_step_direction.dart';
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
        final selected = _selectedPattern(settings);
        final steps = _buildSteps(settings, selected);
        if (steps.isEmpty) return;
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

  MotionPatternDefinition? _selectedPattern(MotionPatternSettings settings) {
    for (final p in settings.patterns) {
      if (p.id == settings.selectedPatternId) return p;
    }
    return settings.patterns.isEmpty ? null : settings.patterns.first;
  }

  List<_PatternStep> _buildSteps(
    MotionPatternSettings settings,
    MotionPatternDefinition? pattern,
  ) {
    if (pattern == null) return const [];

    final List<_PatternStep> result = [];
    for (final step in pattern.steps) {
      switch (step.kind) {
        case MotionStepKind.forward:
          result.add(
            _PatternStep(
              'Forward ${step.forwardMs}ms',
              RoverCommand.forward,
              step.forwardMs,
            ),
          );
        case MotionStepKind.turn:
          final holdMs = (step.turnDegrees * settings.turnMsPerDegree)
              .round()
              .clamp(120, 4000);
          final command = step.turnDirection == MotionStepDirection.left
              ? RoverCommand.left
              : RoverCommand.right;
          result.add(
            _PatternStep(
              'Turn ${step.turnDirection.label} ${step.turnDegrees}°',
              command,
              holdMs,
            ),
          );
      }
    }

    return result;
  }
}

class _PatternStep {
  const _PatternStep(this.label, this.command, this.holdMs);

  final String label;
  final RoverCommand command;
  final int holdMs;
}
