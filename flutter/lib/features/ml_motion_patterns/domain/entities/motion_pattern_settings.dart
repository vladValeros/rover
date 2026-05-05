import 'package:freezed_annotation/freezed_annotation.dart';

import 'motion_pattern_definition.dart';
import 'motion_pattern_step.dart';
import '../enums/motion_step_direction.dart';

part 'motion_pattern_settings.freezed.dart';

const List<MotionPatternDefinition> _defaultMotionPatterns = [
  MotionPatternDefinition(
    id: 'box',
    name: 'Box Pattern',
    steps: [
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
    ],
  ),
  MotionPatternDefinition(
    id: 'figure_eight',
    name: 'Figure-8 Pattern',
    steps: [
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 700),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 700),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 700),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.left,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 700),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.left,
        turnDegrees: 90,
      ),
    ],
  ),
  MotionPatternDefinition(
    id: 'l_pattern',
    name: 'L Pattern',
    steps: [
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 800),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.left,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 800),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.left,
        turnDegrees: 180,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 800),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 90,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 800),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 180,
      ),
    ],
  ),
  MotionPatternDefinition(
    id: 'shuttle',
    name: 'Shuttle (Back & Forth)',
    steps: [
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 1200),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 180,
      ),
      MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 1200),
      MotionPatternStep(
        kind: MotionStepKind.turn,
        turnDirection: MotionStepDirection.right,
        turnDegrees: 180,
      ),
    ],
  ),
];

@freezed
abstract class MotionPatternSettings with _$MotionPatternSettings {
  const factory MotionPatternSettings({
    @Default(false) bool enabled,
    @Default('box') String selectedPatternId,
    @Default(_defaultMotionPatterns) List<MotionPatternDefinition> patterns,
    @Default(5.6) double turnMsPerDegree,
    @Default(120) int interStepPauseMs,
  }) = _MotionPatternSettings;
}
