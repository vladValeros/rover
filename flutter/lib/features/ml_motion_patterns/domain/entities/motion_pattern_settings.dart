import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/motion_pattern_type.dart';

part 'motion_pattern_settings.freezed.dart';

@freezed
abstract class MotionPatternSettings with _$MotionPatternSettings {
  const factory MotionPatternSettings({
    @Default(false) bool enabled,
    @Default(MotionPatternType.box) MotionPatternType pattern,
    @Default(900) int forwardMs,
    @Default(520) int turn90Ms,
    @Default(980) int turn180Ms,
    @Default(120) int interStepPauseMs,
  }) = _MotionPatternSettings;
}
