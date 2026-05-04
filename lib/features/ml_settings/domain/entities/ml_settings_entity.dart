import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../ml_object_detection/domain/entities/object_detection_settings.dart';

part 'ml_settings_entity.freezed.dart';

@freezed
abstract class MlSettingsEntity with _$MlSettingsEntity {
  const factory MlSettingsEntity({
    @Default(ObjectDetectionSettings()) ObjectDetectionSettings objectDetection,
    // Future ML features go here, e.g.:
    // @Default(MotionDetectionSettings()) MotionDetectionSettings motionDetection,
  }) = _MlSettingsEntity;
}
