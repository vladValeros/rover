import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../ml_object_detection/domain/entities/object_detection_settings.dart';
import '../../../ml_object_detection/domain/enums/object_detection_mode.dart';
import '../../domain/entities/ml_settings_entity.dart';

@lazySingleton
class MlSettingsLocalDatasource {
  static const String _odModeKey = 'ml_od_mode';
  static const String _odThresholdKey = 'ml_od_threshold';
  static const String _odIntervalKey = 'ml_od_interval_ms';
  static const String _odDiagnosticsKey = 'ml_od_show_diagnostics';

  Future<MlSettingsEntity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final odSettings = ObjectDetectionSettings(
      mode: ObjectDetectionMode.values[prefs.getInt(_odModeKey) ?? 0],
      confidenceThreshold: prefs.getDouble(_odThresholdKey) ?? 0.45,
      intervalMs: prefs.getInt(_odIntervalKey) ?? 800,
      showDiagnostics: prefs.getBool(_odDiagnosticsKey) ?? true,
    );
    return MlSettingsEntity(objectDetection: odSettings);
  }

  Future<void> saveObjectDetection(ObjectDetectionSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_odModeKey, settings.mode.index);
    await prefs.setDouble(_odThresholdKey, settings.confidenceThreshold);
    await prefs.setInt(_odIntervalKey, settings.intervalMs);
    await prefs.setBool(_odDiagnosticsKey, settings.showDiagnostics);
  }
}
