enum MotionStepDirection { left, right }

extension MotionStepDirectionLabel on MotionStepDirection {
  String get label => switch (this) {
    MotionStepDirection.left => 'Left',
    MotionStepDirection.right => 'Right',
  };
}
