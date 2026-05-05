import 'motion_pattern_step.dart';

class MotionPatternDefinition {
  const MotionPatternDefinition({
    required this.id,
    required this.name,
    required this.steps,
  });

  final String id;
  final String name;
  final List<MotionPatternStep> steps;

  MotionPatternDefinition copyWith({
    String? id,
    String? name,
    List<MotionPatternStep>? steps,
  }) {
    return MotionPatternDefinition(
      id: id ?? this.id,
      name: name ?? this.name,
      steps: steps ?? this.steps,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'steps': steps.map((e) => e.toMap()).toList(),
    };
  }

  static MotionPatternDefinition fromMap(Map<String, dynamic> map) {
    final stepsRaw = map['steps'] as List<dynamic>? ?? const [];
    return MotionPatternDefinition(
      id:
          map['id'] as String? ??
          'pattern_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Custom Pattern',
      steps: stepsRaw
          .whereType<Map>()
          .map((e) => MotionPatternStep.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}
