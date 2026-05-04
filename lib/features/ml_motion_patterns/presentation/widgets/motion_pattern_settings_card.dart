import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ml_settings/presentation/controllers/ml_settings_cubit.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_state.dart';
import '../../../ml_settings/presentation/widgets/ml_feature_card.dart';
import '../../domain/entities/motion_pattern_settings.dart';
import '../../domain/enums/motion_pattern_type.dart';

class MotionPatternSettingsCard extends StatelessWidget {
  const MotionPatternSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MlSettingsCubit, MlSettingsState>(
      builder: (context, state) {
        final settings = state.whenOrNull(loaded: (s) => s.motionPattern);
        if (settings == null) {
          return const Card(child: LinearProgressIndicator());
        }

        final cubit = context.read<MlSettingsCubit>();

        return MlFeatureCard(
          icon: Icons.route_outlined,
          title: 'Motion Patterns',
          description: 'Auto-drive in repeatable command patterns',
          isEnabled: settings.enabled,
          onToggle: (enabled) =>
              cubit.updateMotionPattern(settings.copyWith(enabled: enabled)),
          body: _MotionPatternBody(settings: settings, cubit: cubit),
        );
      },
    );
  }
}

class _MotionPatternBody extends StatefulWidget {
  const _MotionPatternBody({required this.settings, required this.cubit});

  final MotionPatternSettings settings;
  final MlSettingsCubit cubit;

  @override
  State<_MotionPatternBody> createState() => _MotionPatternBodyState();
}

class _MotionPatternBodyState extends State<_MotionPatternBody> {
  late double _forwardMs;
  late double _turn90Ms;
  late double _turn180Ms;

  @override
  void initState() {
    super.initState();
    _forwardMs = widget.settings.forwardMs.toDouble();
    _turn90Ms = widget.settings.turn90Ms.toDouble();
    _turn180Ms = widget.settings.turn180Ms.toDouble();
  }

  @override
  void didUpdateWidget(covariant _MotionPatternBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _forwardMs = widget.settings.forwardMs.toDouble();
      _turn90Ms = widget.settings.turn90Ms.toDouble();
      _turn180Ms = widget.settings.turn180Ms.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Pattern', colorScheme: cs),
        const SizedBox(height: 8),
        DropdownButton<MotionPatternType>(
          value: s.pattern,
          isExpanded: true,
          items: MotionPatternType.values
              .map(
                (pattern) => DropdownMenuItem(
                  value: pattern,
                  child: Text(pattern.label),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            widget.cubit.updateMotionPattern(s.copyWith(pattern: v));
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              final preset = s.pattern.defaultTimings;
              widget.cubit.updateMotionPattern(
                s.copyWith(
                  forwardMs: preset.forwardMs,
                  turn90Ms: preset.turn90Ms,
                  turn180Ms: preset.turn180Ms,
                ),
              );
            },
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Apply Preset Timings'),
          ),
        ),
        const SizedBox(height: 8),
        _SliderRow(
          label: 'Forward Hold (ms)',
          value: _forwardMs,
          min: 300,
          max: 2000,
          divisions: 17,
          onChanged: (v) => setState(() => _forwardMs = v),
          onChangeEnd: (v) => widget.cubit.updateMotionPattern(
            s.copyWith(forwardMs: v.round()),
          ),
        ),
        _SliderRow(
          label: 'Turn 90 Hold (ms)',
          value: _turn90Ms,
          min: 200,
          max: 1500,
          divisions: 13,
          onChanged: (v) => setState(() => _turn90Ms = v),
          onChangeEnd: (v) =>
              widget.cubit.updateMotionPattern(s.copyWith(turn90Ms: v.round())),
        ),
        _SliderRow(
          label: 'Turn 180 Hold (ms)',
          value: _turn180Ms,
          min: 400,
          max: 2400,
          divisions: 20,
          onChanged: (v) => setState(() => _turn180Ms = v),
          onChangeEnd: (v) => widget.cubit.updateMotionPattern(
            s.copyWith(turn180Ms: v.round()),
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
    required this.onChanged,
    required this.onChangeEnd,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;
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
              value.round().toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.round().toString(),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
