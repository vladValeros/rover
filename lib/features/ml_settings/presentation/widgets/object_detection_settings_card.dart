import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/ml_settings_entity.dart';
import '../../domain/enums/object_detection_mode.dart';
import '../controllers/ml_settings_cubit.dart';
import '../controllers/ml_settings_state.dart';

/// A settings card for the Object Detection ML feature.
///
/// To add a new ML feature, duplicate this card and:
///   1. Add a new settings entity field to [MlSettingsEntity].
///   2. Add an `updateXxx` method on [MlSettingsCubit].
///   3. Create a new XxxSettingsCard widget.
///   4. Drop it into [MlSettingsScreen].
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
        final isActive = settings.mode != ObjectDetectionMode.off;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row ──────────────────────────────────────────────
                Row(
                  children: [
                    const Icon(Icons.camera_alt_outlined, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Object Detection',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Detect and label objects in the live stream',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isActive,
                      onChanged: (enabled) {
                        cubit.updateObjectDetection(
                          settings.copyWith(
                            mode: enabled
                                ? ObjectDetectionMode.general
                                : ObjectDetectionMode.off,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                if (isActive) ...[
                  const Divider(height: 24),

                  // ── Detection mode chips ──────────────────────────────────
                  Text(
                    'Detection Mode',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _ModeChip(
                        label: 'General',
                        selected: settings.mode == ObjectDetectionMode.general,
                        onSelected: () => cubit.updateObjectDetection(
                          settings.copyWith(mode: ObjectDetectionMode.general),
                        ),
                      ),
                      _ModeChip(
                        label: 'Person Only',
                        selected:
                            settings.mode == ObjectDetectionMode.personOnly,
                        onSelected: () => cubit.updateObjectDetection(
                          settings.copyWith(
                            mode: ObjectDetectionMode.personOnly,
                          ),
                        ),
                      ),
                      _ModeChip(
                        label: 'Vehicle Only',
                        selected:
                            settings.mode == ObjectDetectionMode.vehicleOnly,
                        onSelected: () => cubit.updateObjectDetection(
                          settings.copyWith(
                            mode: ObjectDetectionMode.vehicleOnly,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Confidence threshold ──────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Confidence',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        settings.confidenceThreshold.toStringAsFixed(2),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Slider(
                    value: settings.confidenceThreshold,
                    min: 0.1,
                    max: 0.95,
                    divisions: 17,
                    label: settings.confidenceThreshold.toStringAsFixed(2),
                    onChangeEnd: (value) => cubit.updateObjectDetection(
                      settings.copyWith(confidenceThreshold: value),
                    ),
                    onChanged: (_) {},
                  ),

                  const SizedBox(height: 8),

                  // ── Detection rate ────────────────────────────────────────
                  Row(
                    children: [
                      Text(
                        'Detection Rate',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<int>(
                        value: settings.intervalMs,
                        items: const [
                          DropdownMenuItem(value: 300, child: Text('Fast')),
                          DropdownMenuItem(value: 800, child: Text('Balanced')),
                          DropdownMenuItem(
                            value: 1500,
                            child: Text('Power Save'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          cubit.updateObjectDetection(
                            settings.copyWith(intervalMs: value),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // ── Diagnostics toggle ────────────────────────────────────
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Show Diagnostics Overlay',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    subtitle: const Text('FPS, latency and frame counters'),
                    value: settings.showDiagnostics,
                    onChanged: (value) => cubit.updateObjectDetection(
                      settings.copyWith(showDiagnostics: value),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
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
