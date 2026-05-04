import 'package:flutter/material.dart';

import '../widgets/object_detection_settings_card.dart';

/// ML & AI Settings screen.
///
/// Each ML feature is isolated in its own card.  To add a new ML type:
///   1. Create a new entity + enum in `ml_settings/domain/`.
///   2. Add a cubit method in [MlSettingsCubit].
///   3. Create a `XxxSettingsCard` widget in `ml_settings/presentation/widgets/`.
///   4. Drop it into the [_featureCards] list below — done.
class MlSettingsScreen extends StatelessWidget {
  const MlSettingsScreen({super.key});

  // ── Add new ML feature cards here ───────────────────────────────────────
  static const List<Widget> _featureCards = [
    ObjectDetectionSettingsCard(),
    // MotionDetectionSettingsCard(),
    // FaceDetectionSettingsCard(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML / AI Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Machine Learning Features',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ..._featureCards,
        ],
      ),
    );
  }
}
