import 'package:flutter/widgets.dart';

import '../../../autopilot/presentation/widgets/autopilot_settings_card.dart';
import '../../../ml_motion_patterns/presentation/widgets/motion_pattern_settings_card.dart';
import '../../../ml_object_detection/domain/enums/object_detection_mode.dart';
import '../../../ml_object_detection/presentation/widgets/object_detection_settings_card.dart';
import '../../domain/entities/ml_settings_entity.dart';

/// Presentation-facing registration descriptor for ML features.
///
/// New ML features should provide one registration entry here so the settings
/// screen can discover and render them consistently.
class MlFeatureRegistration {
  const MlFeatureRegistration({
    required this.id,
    required this.title,
    required this.buildSettingsCard,
    required this.isActive,
  });

  final String id;
  final String title;
  final Widget Function() buildSettingsCard;
  final bool Function(MlSettingsEntity settings) isActive;
}

/// Central registry of ML features shown in settings.
///
/// Contract for adding a new ML feature:
/// 1) Build feature module under lib/features/ml_<feature>/
/// 2) Expose its settings card widget
/// 3) Add one entry here
const List<MlFeatureRegistration> mlFeatureRegistry = [
  MlFeatureRegistration(
    id: 'object_detection',
    title: 'Object Detection',
    buildSettingsCard: ObjectDetectionSettingsCard.new,
    isActive: _isObjectDetectionActive,
  ),
  MlFeatureRegistration(
    id: 'motion_patterns',
    title: 'Motion Patterns',
    buildSettingsCard: MotionPatternSettingsCard.new,
    isActive: _isMotionPatternsActive,
  ),
  MlFeatureRegistration(
    id: 'autopilot',
    title: 'Autopilot',
    buildSettingsCard: AutopilotSettingsCard.new,
    isActive: _isAutopilotActive,
  ),
];

bool _isObjectDetectionActive(MlSettingsEntity settings) =>
    settings.objectDetection.mode != ObjectDetectionMode.off;

bool _isMotionPatternsActive(MlSettingsEntity settings) =>
    settings.motionPattern.enabled;

bool _isAutopilotActive(MlSettingsEntity settings) =>
    settings.autopilot.enabled;
