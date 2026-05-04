import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ml_motion_patterns/domain/entities/motion_pattern_settings.dart';
import '../../../ml_motion_patterns/domain/enums/motion_pattern_type.dart';
import '../../../ml_object_detection/domain/entities/object_detection_settings.dart';
import '../../../ml_object_detection/domain/enums/object_detection_mode.dart';
import '../../domain/entities/ml_settings_entity.dart';

@lazySingleton
class MlSettingsLocalDatasource {
  static const String _odModeKey = 'ml_od_mode';
  static const String _odThresholdKey = 'ml_od_threshold';
  static const String _odIntervalKey = 'ml_od_interval_ms';
  static const String _odDiagnosticsKey = 'ml_od_show_diagnostics';

  static const String _mpEnabledKey = 'ml_mp_enabled';
  static const String _mpPatternKey = 'ml_mp_pattern';
  static const String _mpForwardMsKey = 'ml_mp_forward_ms';
  static const String _mpTurn90MsKey = 'ml_mp_turn90_ms';
  static const String _mpTurn180MsKey = 'ml_mp_turn180_ms';
  static const String _mpInterStepPauseMsKey = 'ml_mp_inter_step_pause_ms';

  Future<MlSettingsEntity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final odSettings = ObjectDetectionSettings(
      mode: ObjectDetectionMode.values[prefs.getInt(_odModeKey) ?? 0],
      confidenceThreshold: prefs.getDouble(_odThresholdKey) ?? 0.45,
      intervalMs: prefs.getInt(_odIntervalKey) ?? 800,
      showDiagnostics: prefs.getBool(_odDiagnosticsKey) ?? true,
    );
    final mpSettings = MotionPatternSettings(
      enabled: prefs.getBool(_mpEnabledKey) ?? false,
      pattern: MotionPatternType.values[prefs.getInt(_mpPatternKey) ?? 0],
      forwardMs: prefs.getInt(_mpForwardMsKey) ?? 900,
      turn90Ms: prefs.getInt(_mpTurn90MsKey) ?? 520,
      turn180Ms: prefs.getInt(_mpTurn180MsKey) ?? 980,
      interStepPauseMs: prefs.getInt(_mpInterStepPauseMsKey) ?? 120,
    );
    return MlSettingsEntity(
      objectDetection: odSettings,
      motionPattern: mpSettings,
    );
  }

  Future<void> saveObjectDetection(ObjectDetectionSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_odModeKey, settings.mode.index);
    await prefs.setDouble(_odThresholdKey, settings.confidenceThreshold);
    await prefs.setInt(_odIntervalKey, settings.intervalMs);
    await prefs.setBool(_odDiagnosticsKey, settings.showDiagnostics);
  }

  Future<void> saveMotionPattern(MotionPatternSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mpEnabledKey, settings.enabled);
    await prefs.setInt(_mpPatternKey, settings.pattern.index);
    await prefs.setInt(_mpForwardMsKey, settings.forwardMs);
    await prefs.setInt(_mpTurn90MsKey, settings.turn90Ms);
    await prefs.setInt(_mpTurn180MsKey, settings.turn180Ms);
    await prefs.setInt(_mpInterStepPauseMsKey, settings.interStepPauseMs);
  }
}
