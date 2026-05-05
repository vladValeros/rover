import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ml_settings/presentation/controllers/ml_settings_cubit.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_state.dart';
import '../../../ml_settings/presentation/widgets/ml_feature_card.dart';
import '../../domain/entities/autopilot_settings.dart';

class AutopilotSettingsCard extends StatelessWidget {
  const AutopilotSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MlSettingsCubit, MlSettingsState>(
      builder: (context, state) {
        final settings = state.whenOrNull(loaded: (s) => s.autopilot);
        if (settings == null) {
          return const Card(child: LinearProgressIndicator());
        }
        final cubit = context.read<MlSettingsCubit>();

        return MlFeatureCard(
          icon: Icons.smart_toy_outlined,
          title: 'Autopilot',
          description:
              'Obstacle-avoidance using on-device depth estimation (MiDaS)',
          isEnabled: settings.enabled,
          onToggle: (enabled) =>
              cubit.updateAutopilot(settings.copyWith(enabled: enabled)),
          body: _AutopilotBody(settings: settings, cubit: cubit),
        );
      },
    );
  }
}

class _AutopilotBody extends StatelessWidget {
  const _AutopilotBody({required this.settings, required this.cubit});

  final AutopilotSettings settings;
  final MlSettingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Info note ─────────────────────────────────────────────────────
        Text(
          'When enabled, the autopilot toggle appears on the control screen. '
          'Activate it there to start the avoid loop.',
          style: tt.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // ── Block threshold ───────────────────────────────────────────────
        _SliderRow(
          label: 'Block threshold',
          value: settings.blockThreshold,
          min: 0.3,
          max: 0.9,
          divisions: 12,
          displayFn: (v) => v.toStringAsFixed(2),
          onChangeEnd: (v) =>
              cubit.updateAutopilot(settings.copyWith(blockThreshold: v)),
        ),
        Text(
          'Depth above this value = obstacle ahead. '
          'Lower = more sensitive.',
          style: tt.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // ── Clear threshold ───────────────────────────────────────────────
        _SliderRow(
          label: 'Clear threshold',
          value: settings.clearThreshold,
          min: 0.1,
          max: 0.6,
          divisions: 10,
          displayFn: (v) => v.toStringAsFixed(2),
          onChangeEnd: (v) =>
              cubit.updateAutopilot(settings.copyWith(clearThreshold: v)),
        ),
        Text(
          'Depth below this value = path is clear. '
          'Must be lower than block threshold.',
          style: tt.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        // ── Loop interval ─────────────────────────────────────────────────
        _SliderRow(
          label: 'Loop interval (ms)',
          value: settings.loopIntervalMs.toDouble(),
          min: 200,
          max: 1000,
          divisions: 16,
          displayFn: (v) => v.round().toString(),
          onChangeEnd: (v) => cubit.updateAutopilot(
            settings.copyWith(loopIntervalMs: v.round()),
          ),
        ),

        // ── Turn pulse ────────────────────────────────────────────────────
        _SliderRow(
          label: 'Turn pulse (ms)',
          value: settings.turnPulseMs.toDouble(),
          min: 100,
          max: 800,
          divisions: 14,
          displayFn: (v) => v.round().toString(),
          onChangeEnd: (v) =>
              cubit.updateAutopilot(settings.copyWith(turnPulseMs: v.round())),
        ),
        Text(
          'Duration of each short turn burst while avoiding. '
          'Lower = slower, more patient turning.',
          style: tt.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayFn,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) displayFn;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(
              displayFn(value),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: displayFn(value),
          onChanged: (_) {},
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}
