import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../autopilot/domain/entities/autopilot_settings.dart';
import '../../../ml_motion_detection/domain/entities/motion_detection_settings.dart';
import '../../../ml_motion_detection/domain/enums/motion_detection_action_mode.dart';
import '../../../ml_motion_patterns/domain/entities/motion_pattern_definition.dart';
import '../../../ml_motion_patterns/domain/entities/motion_pattern_settings.dart';
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
  static const String _mpSelectedPatternIdKey = 'ml_mp_selected_pattern_id';
  static const String _mpPatternsJsonKey = 'ml_mp_patterns_json';
  static const String _mpTurnMsPerDegreeKey = 'ml_mp_turn_ms_per_degree';
  static const String _mpInterStepPauseMsKey = 'ml_mp_inter_step_pause_ms';

  // Legacy keys kept for migration fallback.
  static const String _mpPatternKeyLegacy = 'ml_mp_pattern';

  static const String _apJsonKey = 'ml_ap_json';

  static const String _mdEnabledKey = 'ml_md_enabled';
  static const String _mdShowOverlayKey = 'ml_md_show_overlay';
  static const String _mdShowDiagnosticsKey = 'ml_md_show_diagnostics';
  static const String _mdSensitivityKey = 'ml_md_sensitivity';
  static const String _mdSampleIntervalMsKey = 'ml_md_sample_interval_ms';
  static const String _mdCooldownMsKey = 'ml_md_cooldown_ms';
  static const String _mdActionModeKey = 'ml_md_action_mode';
  static const String _mdRoutinePulseMsKey = 'ml_md_routine_pulse_ms';
  static const String _mdRoutineCyclesKey = 'ml_md_routine_cycles';
  static const String _mdLedOnDuringRoutineKey = 'ml_md_led_on_during_routine';

  Future<MlSettingsEntity> load() async {
    final prefs = await SharedPreferences.getInstance();
    final odSettings = ObjectDetectionSettings(
      mode: ObjectDetectionMode.values[prefs.getInt(_odModeKey) ?? 0],
      confidenceThreshold: prefs.getDouble(_odThresholdKey) ?? 0.45,
      intervalMs: prefs.getInt(_odIntervalKey) ?? 800,
      showDiagnostics: prefs.getBool(_odDiagnosticsKey) ?? true,
    );
    final patternsJson = prefs.getString(_mpPatternsJsonKey);
    final List<MotionPatternDefinition> patterns = _decodePatterns(
      patternsJson,
    );

    final selectedPatternId =
        prefs.getString(_mpSelectedPatternIdKey) ??
        _migrateLegacyPatternId(prefs.getInt(_mpPatternKeyLegacy) ?? 0);

    final mpSettings = MotionPatternSettings(
      enabled: prefs.getBool(_mpEnabledKey) ?? false,
      selectedPatternId: selectedPatternId,
      patterns: patterns,
      turnMsPerDegree: prefs.getDouble(_mpTurnMsPerDegreeKey) ?? 5.6,
      interStepPauseMs: prefs.getInt(_mpInterStepPauseMsKey) ?? 120,
    );

    final savedActionModeIndex = prefs.getInt(_mdActionModeKey);
    final actionMode =
        (savedActionModeIndex != null &&
            savedActionModeIndex >= 0 &&
            savedActionModeIndex < MotionDetectionActionMode.values.length)
        ? MotionDetectionActionMode.values[savedActionModeIndex]
        : MotionDetectionActionMode.routine;

    final mdSettings = MotionDetectionSettings(
      enabled: prefs.getBool(_mdEnabledKey) ?? false,
      showOverlay: prefs.getBool(_mdShowOverlayKey) ?? true,
      showDiagnostics: prefs.getBool(_mdShowDiagnosticsKey) ?? false,
      sensitivity: prefs.getDouble(_mdSensitivityKey) ?? 0.22,
      sampleIntervalMs: prefs.getInt(_mdSampleIntervalMsKey) ?? 350,
      cooldownMs: prefs.getInt(_mdCooldownMsKey) ?? 2500,
      actionMode: actionMode,
      routinePulseMs: prefs.getInt(_mdRoutinePulseMsKey) ?? 140,
      routineCycles: prefs.getInt(_mdRoutineCyclesKey) ?? 2,
      ledOnDuringRoutine: prefs.getBool(_mdLedOnDuringRoutineKey) ?? true,
    );

    return MlSettingsEntity(
      objectDetection: odSettings,
      motionPattern: mpSettings,
      autopilot: _decodeAutopilot(prefs.getString(_apJsonKey)),
      motionDetection: mdSettings,
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
    await prefs.setString(_mpSelectedPatternIdKey, settings.selectedPatternId);
    await prefs.setString(
      _mpPatternsJsonKey,
      jsonEncode(settings.patterns.map((e) => e.toMap()).toList()),
    );
    await prefs.setDouble(_mpTurnMsPerDegreeKey, settings.turnMsPerDegree);
    await prefs.setInt(_mpInterStepPauseMsKey, settings.interStepPauseMs);
  }

  Future<void> saveAutopilot(AutopilotSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apJsonKey, jsonEncode(settings.toMap()));
  }

  Future<void> saveMotionDetection(MotionDetectionSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_mdEnabledKey, settings.enabled);
    await prefs.setBool(_mdShowOverlayKey, settings.showOverlay);
    await prefs.setBool(_mdShowDiagnosticsKey, settings.showDiagnostics);
    await prefs.setDouble(_mdSensitivityKey, settings.sensitivity);
    await prefs.setInt(_mdSampleIntervalMsKey, settings.sampleIntervalMs);
    await prefs.setInt(_mdCooldownMsKey, settings.cooldownMs);
    await prefs.setInt(_mdActionModeKey, settings.actionMode.index);
    await prefs.setInt(_mdRoutinePulseMsKey, settings.routinePulseMs);
    await prefs.setInt(_mdRoutineCyclesKey, settings.routineCycles);
    await prefs.setBool(_mdLedOnDuringRoutineKey, settings.ledOnDuringRoutine);
  }

  List<MotionPatternDefinition> _decodePatterns(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) {
      return const MotionPatternSettings().patterns;
    }
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! List) return const MotionPatternSettings().patterns;
      final patterns = decoded
          .whereType<Map>()
          .map(
            (e) =>
                MotionPatternDefinition.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList();
      return patterns.isEmpty
          ? const MotionPatternSettings().patterns
          : patterns;
    } catch (_) {
      return const MotionPatternSettings().patterns;
    }
  }

  String _migrateLegacyPatternId(int legacyIndex) {
    const ids = ['box', 'figure_eight', 'l_pattern', 'shuttle'];
    if (legacyIndex < 0 || legacyIndex >= ids.length) return 'box';
    return ids[legacyIndex];
  }

  AutopilotSettings _decodeAutopilot(String? json) {
    if (json == null || json.isEmpty) return const AutopilotSettings();
    try {
      final m = jsonDecode(json);
      if (m is Map<String, dynamic>) return AutopilotSettings.fromMap(m);
    } catch (_) {}
    return const AutopilotSettings();
  }
}
