import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/object_detection_mode.dart';

part 'object_detection_settings.freezed.dart';

@freezed
abstract class ObjectDetectionSettings with _$ObjectDetectionSettings {
  const factory ObjectDetectionSettings({
    @Default(ObjectDetectionMode.off) ObjectDetectionMode mode,
    @Default(0.45) double confidenceThreshold,
    @Default(800) int intervalMs,
    @Default(true) bool showDiagnostics,
  }) = _ObjectDetectionSettings;
}
