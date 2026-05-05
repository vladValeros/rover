/// Settings for the autopilot obstacle-avoidance feature.
class AutopilotSettings {
  const AutopilotSettings({
    this.enabled = false,
    this.blockThreshold = 0.60,
    this.clearThreshold = 0.40,
    this.loopIntervalMs = 500,
    this.turnPulseMs = 300,
  });

  /// Whether the autopilot feature is active.
  final bool enabled;

  /// Centre-depth mean above this → path is blocked (0–1, inverse depth).
  final double blockThreshold;

  /// Centre-depth mean below this → path is clear (0–1, inverse depth).
  final double clearThreshold;

  /// How often the avoid loop runs (ms).
  final int loopIntervalMs;

  /// Duration of each slow-turn pulse when avoiding (ms).
  final int turnPulseMs;

  AutopilotSettings copyWith({
    bool? enabled,
    double? blockThreshold,
    double? clearThreshold,
    int? loopIntervalMs,
    int? turnPulseMs,
  }) {
    return AutopilotSettings(
      enabled: enabled ?? this.enabled,
      blockThreshold: blockThreshold ?? this.blockThreshold,
      clearThreshold: clearThreshold ?? this.clearThreshold,
      loopIntervalMs: loopIntervalMs ?? this.loopIntervalMs,
      turnPulseMs: turnPulseMs ?? this.turnPulseMs,
    );
  }

  Map<String, dynamic> toMap() => {
    'enabled': enabled,
    'blockThreshold': blockThreshold,
    'clearThreshold': clearThreshold,
    'loopIntervalMs': loopIntervalMs,
    'turnPulseMs': turnPulseMs,
  };

  factory AutopilotSettings.fromMap(Map<String, dynamic> m) =>
      AutopilotSettings(
        enabled: m['enabled'] as bool? ?? false,
        blockThreshold: (m['blockThreshold'] as num?)?.toDouble() ?? 0.60,
        clearThreshold: (m['clearThreshold'] as num?)?.toDouble() ?? 0.40,
        loopIntervalMs: m['loopIntervalMs'] as int? ?? 500,
        turnPulseMs: m['turnPulseMs'] as int? ?? 300,
      );
}
