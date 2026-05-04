import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../controllers/ml_settings_cubit.dart';
import '../controllers/ml_settings_state.dart';
import '../registry/ml_feature_registry.dart';

/// ML & AI Settings screen.
///
/// Lists every registered ML feature as an isolated card.
/// Each card manages its own state — features are completely independent.
///
/// Add new ML features by registering one entry in [mlFeatureRegistry].
class MlSettingsScreen extends StatelessWidget {
  const MlSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML / AI Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MlStatusBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                _SectionHeader(
                  title: 'Machine Learning Features',
                  subtitle: '${mlFeatureRegistry.length} feature(s) available',
                ),
                ...mlFeatureRegistry.map(
                  (feature) => feature.buildSettingsCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Status banner ─────────────────────────────────────────────────────────────

class _MlStatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MlSettingsCubit, MlSettingsState>(
      builder: (context, state) {
        final settings = state.whenOrNull(loaded: (s) => s);
        if (settings == null) {
          return const LinearProgressIndicator();
        }

        // Count how many features are currently active.
        final activeCount = mlFeatureRegistry
            .where((feature) => feature.isActive(settings))
            .length;

        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: activeCount > 0
                ? colorScheme.primaryContainer.withAlpha(180)
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                activeCount > 0 ? Icons.smart_toy : Icons.smart_toy_outlined,
                size: 18,
                color: activeCount > 0
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                activeCount > 0
                    ? '$activeCount ML feature${activeCount > 1 ? 's' : ''} active'
                    : 'No ML features active',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: activeCount > 0
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 0.3,
            ),
          ),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
