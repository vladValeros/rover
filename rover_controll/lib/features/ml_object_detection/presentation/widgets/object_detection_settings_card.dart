import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ml_settings/presentation/controllers/ml_settings_cubit.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_state.dart';
import '../../domain/entities/object_detection_settings.dart';
import '../../domain/enums/object_detection_mode.dart';
import '../../../ml_settings/presentation/widgets/ml_feature_card.dart';

/// Settings card for the Object Detection ML feature.
class ObjectDetectionSettingsCard extends StatelessWidget {
  const ObjectDetectionSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MlSettingsCubit, MlSettingsState>(
      builder: (context, state) {
        final settings = state.whenOrNull(loaded: (s) => s.objectDetection);
        if (settings == null) {
          return const Card(child: LinearProgressIndicator());
        }

        final cubit = context.read<MlSettingsCubit>();
        final isEnabled = settings.mode != ObjectDetectionMode.off;

        return MlFeatureCard(
          icon: Icons.camera_alt_outlined,
          title: 'Object Detection',
          description: 'Detect and label objects in the live stream',
          isEnabled: isEnabled,
          onToggle: (enabled) => cubit.updateObjectDetection(
            settings.copyWith(
              mode: enabled
                  ? ObjectDetectionMode.general
                  : ObjectDetectionMode.off,
            ),
          ),
          body: _ObjectDetectionBody(settings: settings, cubit: cubit),
        );
      },
    );
  }
}

class _ObjectDetectionBody extends StatefulWidget {
  const _ObjectDetectionBody({required this.settings, required this.cubit});

  final ObjectDetectionSettings settings;
  final MlSettingsCubit cubit;

  @override
  State<_ObjectDetectionBody> createState() => _ObjectDetectionBodyState();
}

class _ObjectDetectionBodyState extends State<_ObjectDetectionBody> {
  late double _localThreshold;

  @override
  void initState() {
    super.initState();
    _localThreshold = widget.settings.confidenceThreshold;
  }

  @override
  void didUpdateWidget(_ObjectDetectionBody old) {
    super.didUpdateWidget(old);
    if (old.settings.confidenceThreshold !=
        widget.settings.confidenceThreshold) {
      _localThreshold = widget.settings.confidenceThreshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final s = widget.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: 'Detection Mode', colorScheme: colorScheme),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _ModeChip(
              label: 'General',
              selected: s.mode == ObjectDetectionMode.general,
              onSelected: () => widget.cubit.updateObjectDetection(
                s.copyWith(mode: ObjectDetectionMode.general),
              ),
            ),
            _ModeChip(
              label: 'Person Only',
              selected: s.mode == ObjectDetectionMode.personOnly,
              onSelected: () => widget.cubit.updateObjectDetection(
                s.copyWith(mode: ObjectDetectionMode.personOnly),
              ),
            ),
            _ModeChip(
              label: 'Vehicle Only',
              selected: s.mode == ObjectDetectionMode.vehicleOnly,
              onSelected: () => widget.cubit.updateObjectDetection(
                s.copyWith(mode: ObjectDetectionMode.vehicleOnly),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _SectionLabel(label: 'Confidence', colorScheme: colorScheme),
            const Spacer(),
            Text(
              _localThreshold.toStringAsFixed(2),
              style: textTheme.bodyMedium?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(
          value: _localThreshold,
          min: 0.1,
          max: 0.95,
          divisions: 17,
          label: _localThreshold.toStringAsFixed(2),
          onChanged: (v) => setState(() => _localThreshold = v),
          onChangeEnd: (v) => widget.cubit.updateObjectDetection(
            s.copyWith(confidenceThreshold: v),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _SectionLabel(label: 'Detection Rate', colorScheme: colorScheme),
            const SizedBox(width: 12),
            DropdownButton<int>(
              value: s.intervalMs,
              isDense: true,
              items: const [
                DropdownMenuItem(value: 300, child: Text('Fast  (~3 fps)')),
                DropdownMenuItem(
                  value: 800,
                  child: Text('Balanced  (~1.2 fps)'),
                ),
                DropdownMenuItem(
                  value: 1500,
                  child: Text('Power Save  (~0.7 fps)'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                widget.cubit.updateObjectDetection(s.copyWith(intervalMs: v));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Diagnostics Overlay', style: textTheme.labelLarge),
          subtitle: const Text(
            'Shows latency, FPS and frame counters on stream',
          ),
          value: s.showDiagnostics,
          onChanged: (v) => widget.cubit.updateObjectDetection(
            s.copyWith(showDiagnostics: v),
          ),
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

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}
