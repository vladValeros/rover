part of 'motion_detection_cubit.dart';

enum MotionDetectionStatus { idle, monitoring, detected, routine }

class MotionDetectionState {
  const MotionDetectionState({
    this.status = MotionDetectionStatus.idle,
    this.lastScore = 0.0,
    this.enabled = false,
  });

  final MotionDetectionStatus status;

  /// Latest normalised changed-pixel score from the last analysed frame [0..1].
  final double lastScore;

  /// Whether the feature is currently enabled via settings.
  final bool enabled;

  MotionDetectionState copyWith({
    MotionDetectionStatus? status,
    double? lastScore,
    bool? enabled,
  }) {
    return MotionDetectionState(
      status: status ?? this.status,
      lastScore: lastScore ?? this.lastScore,
      enabled: enabled ?? this.enabled,
    );
  }
}
