import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../ml_motion_patterns/domain/entities/motion_pattern_settings.dart';
import '../../../ml_object_detection/domain/entities/object_detection_settings.dart';

part 'ml_settings_entity.freezed.dart';

@freezed
abstract class MlSettingsEntity with _$MlSettingsEntity {
  const factory MlSettingsEntity({
    @Default(ObjectDetectionSettings()) ObjectDetectionSettings objectDetection,
    @Default(MotionPatternSettings()) MotionPatternSettings motionPattern,
  }) = _MlSettingsEntity;
}
