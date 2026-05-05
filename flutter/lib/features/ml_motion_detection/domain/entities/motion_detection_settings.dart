import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/motion_detection_action_mode.dart';

part 'motion_detection_settings.freezed.dart';

@freezed
abstract class MotionDetectionSettings with _$MotionDetectionSettings {
  const factory MotionDetectionSettings({
    @Default(false) bool enabled,
    @Default(true) bool showOverlay,
    @Default(false) bool showDiagnostics,
    @Default(0.82) double sensitivity,
    @Default(350) int sampleIntervalMs,
    @Default(2500) int cooldownMs,
    @Default(MotionDetectionActionMode.routine)
    MotionDetectionActionMode actionMode,
    @Default(140) int routinePulseMs,
    @Default(2) int routineCycles,
    @Default(true) bool ledOnDuringRoutine,
  }) = _MotionDetectionSettings;
}
