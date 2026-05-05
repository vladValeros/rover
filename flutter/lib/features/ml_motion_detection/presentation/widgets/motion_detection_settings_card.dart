import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ml_settings/presentation/controllers/ml_settings_cubit.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_state.dart';
import '../../../ml_settings/presentation/widgets/ml_feature_card.dart';
import '../../domain/entities/motion_detection_settings.dart';
import '../../domain/enums/motion_detection_action_mode.dart';

class MotionDetectionSettingsCard extends StatelessWidget {
  const MotionDetectionSettingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MlSettingsCubit, MlSettingsState>(
      builder: (context, state) {
        final settings = state.whenOrNull(loaded: (s) => s.motionDetection);
        if (settings == null) {
          return const Card(child: LinearProgressIndicator());
        }

        final cubit = context.read<MlSettingsCubit>();

        return MlFeatureCard(
          icon: Icons.motion_photos_on_outlined,
          title: 'Motion Detection',
          description: 'Detect scene motion from live stream frame differences',
          isEnabled: settings.enabled,
          onToggle: (enabled) =>
              cubit.updateMotionDetection(settings.copyWith(enabled: enabled)),
          body: _MotionDetectionBody(settings: settings, cubit: cubit),
        );
      },
    );
  }
}

class _MotionDetectionBody extends StatefulWidget {
  const _MotionDetectionBody({required this.settings, required this.cubit});

  final MotionDetectionSettings settings;
  final MlSettingsCubit cubit;

  @override
  State<_MotionDetectionBody> createState() => _MotionDetectionBodyState();
}

class _MotionDetectionBodyState extends State<_MotionDetectionBody> {
  late double _localSensitivity;
  late double _localSampleMs;
  late double _localCooldownMs;
  late double _localPulseMs;
  late double _localCycles;

  @override
  void initState() {
    super.initState();
    _syncFrom(widget.settings);
  }

  @override
  void didUpdateWidget(covariant _MotionDetectionBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.settings != widget.settings) {
      _syncFrom(widget.settings);
    }
  }

  void _syncFrom(MotionDetectionSettings s) {
    _localSensitivity = s.sensitivity;
    _localSampleMs = s.sampleIntervalMs.toDouble();
    _localCooldownMs = s.cooldownMs.toDouble();
    _localPulseMs = s.routinePulseMs.toDouble();
    _localCycles = s.routineCycles.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('On Detect', style: textTheme.labelLarge),
            const SizedBox(width: 12),
            DropdownButton<MotionDetectionActionMode>(
              value: s.actionMode,
              isDense: true,
              items: const [
                DropdownMenuItem(
                  value: MotionDetectionActionMode.overlayOnly,
                  child: Text('Overlay only'),
                ),
                DropdownMenuItem(
                  value: MotionDetectionActionMode.routine,
                  child: Text('Routine only (blink-turn + LED)'),
                ),
                DropdownMenuItem(
                  value: MotionDetectionActionMode.snapshot,
                  child: Text('Snapshot only'),
                ),
                DropdownMenuItem(
                  value: MotionDetectionActionMode.lightAndSnapshot,
                  child: Text('Light (2.5s) + snapshot'),
                ),
              ],
              onChanged: (v) {
                if (v == null) return;
                widget.cubit.updateMotionDetection(s.copyWith(actionMode: v));
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Show Motion Overlay', style: textTheme.labelLarge),
          subtitle: const Text('Draw motion status/region on stream'),
          value: s.showOverlay,
          onChanged: (v) =>
              widget.cubit.updateMotionDetection(s.copyWith(showOverlay: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('Show Diagnostics', style: textTheme.labelLarge),
          subtitle: const Text('Include motion detector stats in overlay'),
          value: s.showDiagnostics,
          onChanged: (v) => widget.cubit.updateMotionDetection(
            s.copyWith(showDiagnostics: v),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sensitivity (${_localSensitivity.toStringAsFixed(2)})',
          style: textTheme.labelLarge,
        ),
        Slider(
          min: 0.60,
          max: 0.95,
          divisions: 35,
          label: _localSensitivity.toStringAsFixed(2),
          value: _localSensitivity,
          onChanged: (v) => setState(() => _localSensitivity = v),
          onChangeEnd: (v) =>
              widget.cubit.updateMotionDetection(s.copyWith(sensitivity: v)),
        ),
        Text(
          'Sampling Rate (${_localSampleMs.round()} ms)',
          style: textTheme.labelLarge,
        ),
        Slider(
          min: 120,
          max: 1200,
          divisions: 36,
          label: '${_localSampleMs.round()} ms',
          value: _localSampleMs,
          onChanged: (v) => setState(() => _localSampleMs = v),
          onChangeEnd: (v) => widget.cubit.updateMotionDetection(
            s.copyWith(sampleIntervalMs: v.round()),
          ),
        ),
        Text(
          'Cooldown (${_localCooldownMs.round()} ms)',
          style: textTheme.labelLarge,
        ),
        Slider(
          min: 500,
          max: 10000,
          divisions: 38,
          label: '${_localCooldownMs.round()} ms',
          value: _localCooldownMs,
          onChanged: (v) => setState(() => _localCooldownMs = v),
          onChangeEnd: (v) => widget.cubit.updateMotionDetection(
            s.copyWith(cooldownMs: v.round()),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Routine Pulse (${_localPulseMs.round()} ms)',
          style: textTheme.labelLarge,
        ),
        Slider(
          min: 60,
          max: 400,
          divisions: 34,
          label: '${_localPulseMs.round()} ms',
          value: _localPulseMs,
          onChanged: (v) => setState(() => _localPulseMs = v),
          onChangeEnd: (v) => widget.cubit.updateMotionDetection(
            s.copyWith(routinePulseMs: v.round()),
          ),
        ),
        Text(
          'Routine Cycles (${_localCycles.round()})',
          style: textTheme.labelLarge,
        ),
        Slider(
          min: 1,
          max: 4,
          divisions: 3,
          label: _localCycles.round().toString(),
          value: _localCycles,
          onChanged: (v) => setState(() => _localCycles = v),
          onChangeEnd: (v) => widget.cubit.updateMotionDetection(
            s.copyWith(routineCycles: v.round()),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('LED During Routine', style: textTheme.labelLarge),
          value: s.ledOnDuringRoutine,
          onChanged: (v) => widget.cubit.updateMotionDetection(
            s.copyWith(ledOnDuringRoutine: v),
          ),
        ),
      ],
    );
  }
}
