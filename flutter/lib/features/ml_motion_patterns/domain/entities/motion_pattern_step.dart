import '../enums/motion_step_direction.dart';

enum MotionStepKind { forward, turn }

class MotionPatternStep {
  const MotionPatternStep({
    required this.kind,
    this.forwardMs = 1000,
    this.turnDirection = MotionStepDirection.right,
    this.turnDegrees = 90,
  });

  final MotionStepKind kind;
  final int forwardMs;
  final MotionStepDirection turnDirection;
  final int turnDegrees;

  MotionPatternStep copyWith({
    MotionStepKind? kind,
    int? forwardMs,
    MotionStepDirection? turnDirection,
    int? turnDegrees,
  }) {
    return MotionPatternStep(
      kind: kind ?? this.kind,
      forwardMs: forwardMs ?? this.forwardMs,
      turnDirection: turnDirection ?? this.turnDirection,
      turnDegrees: turnDegrees ?? this.turnDegrees,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kind': kind.name,
      'forwardMs': forwardMs,
      'turnDirection': turnDirection.name,
      'turnDegrees': turnDegrees,
    };
  }

  static MotionPatternStep fromMap(Map<String, dynamic> map) {
    final kindName = map['kind'] as String? ?? MotionStepKind.forward.name;
    final directionName =
        map['turnDirection'] as String? ?? MotionStepDirection.right.name;

    return MotionPatternStep(
      kind: MotionStepKind.values.firstWhere(
        (e) => e.name == kindName,
        orElse: () => MotionStepKind.forward,
      ),
      forwardMs: (map['forwardMs'] as num?)?.toInt() ?? 1000,
      turnDirection: MotionStepDirection.values.firstWhere(
        (e) => e.name == directionName,
        orElse: () => MotionStepDirection.right,
      ),
      turnDegrees: (map['turnDegrees'] as num?)?.toInt() ?? 90,
    );
  }

  String get summary {
    return switch (kind) {
      MotionStepKind.forward => 'Forward ${forwardMs}ms',
      MotionStepKind.turn =>
        'Turn ${turnDirection.label} ${turnDegrees.toString()}°',
    };
  }
}
