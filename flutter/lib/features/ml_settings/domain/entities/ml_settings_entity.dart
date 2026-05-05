import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../autopilot/domain/entities/autopilot_settings.dart';
import '../../../ml_motion_detection/domain/entities/motion_detection_settings.dart';
import '../../../ml_motion_patterns/domain/entities/motion_pattern_settings.dart';
import '../../../ml_object_detection/domain/entities/object_detection_settings.dart';

part 'ml_settings_entity.freezed.dart';

@freezed
abstract class MlSettingsEntity with _$MlSettingsEntity {
  const factory MlSettingsEntity({
    @Default(ObjectDetectionSettings()) ObjectDetectionSettings objectDetection,
    @Default(MotionPatternSettings()) MotionPatternSettings motionPattern,
    @Default(AutopilotSettings()) AutopilotSettings autopilot,
    @Default(MotionDetectionSettings()) MotionDetectionSettings motionDetection,
  }) = _MlSettingsEntity;
}
