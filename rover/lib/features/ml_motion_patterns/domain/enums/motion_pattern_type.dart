enum MotionPatternType { box, figureEight, lPattern, shuttle }

extension MotionPatternTypeLabel on MotionPatternType {
  String get label => switch (this) {
    MotionPatternType.box => 'Box Pattern',
    MotionPatternType.figureEight => 'Figure-8 Pattern',
    MotionPatternType.lPattern => 'L Pattern',
    MotionPatternType.shuttle => 'Shuttle (Back & Forth)',
  };

  /// Recommended timing defaults for each pattern.
  ({int forwardMs, int turn90Ms, int turn180Ms}) get defaultTimings =>
      switch (this) {
        MotionPatternType.box => (
          forwardMs: 900,
          turn90Ms: 520,
          turn180Ms: 980,
        ),
        MotionPatternType.figureEight => (
          forwardMs: 700,
          turn90Ms: 480,
          turn180Ms: 900,
        ),
        MotionPatternType.lPattern => (
          forwardMs: 800,
          turn90Ms: 500,
          turn180Ms: 960,
        ),
        MotionPatternType.shuttle => (
          forwardMs: 1200,
          turn90Ms: 520,
          turn180Ms: 980,
        ),
      };
}
