import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../ml_settings/presentation/controllers/ml_settings_cubit.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_state.dart';
import '../../../ml_settings/presentation/widgets/ml_feature_card.dart';
import '../../domain/entities/motion_pattern_definition.dart';
import '../../domain/entities/motion_pattern_settings.dart';
import '../../domain/entities/motion_pattern_step.dart';
import '../../domain/enums/motion_step_direction.dart';

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
  MotionPatternDefinition _selected(MotionPatternSettings s) {
    for (final p in s.patterns) {
      if (p.id == s.selectedPatternId) return p;
    }
    return s.patterns.first;
  }

  Future<void> _save(MotionPatternSettings s) {
    return widget.cubit.updateMotionPattern(s);
  }

  Future<void> _replaceSelected(
    MotionPatternSettings s,
    MotionPatternDefinition updated,
  ) {
    final patterns = s.patterns
        .map((p) => p.id == updated.id ? updated : p)
        .toList();
    return _save(s.copyWith(patterns: patterns));
  }

  Future<void> _addPattern(MotionPatternSettings s) {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newPattern = MotionPatternDefinition(
      id: id,
      name: 'Custom ${s.patterns.length + 1}',
      steps: const [
        MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
      ],
    );
    return _save(
      s.copyWith(patterns: [...s.patterns, newPattern], selectedPatternId: id),
    );
  }

  Future<void> _deleteSelected(MotionPatternSettings s) {
    if (s.patterns.length <= 1) return Future.value();
    final remaining = s.patterns
        .where((p) => p.id != s.selectedPatternId)
        .toList();
    return _save(
      s.copyWith(patterns: remaining, selectedPatternId: remaining.first.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final selected = _selected(s);
    final turnMsPerDegree = s.turnMsPerDegree;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: selected.id,
                isExpanded: true,
                items: s.patterns
                    .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern.id,
                        child: Text(pattern.name),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  _save(s.copyWith(selectedPatternId: v));
                },
              ),
            ),
            IconButton(
              tooltip: 'Add Pattern',
              onPressed: () => _addPattern(s),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Delete Pattern',
              onPressed: s.patterns.length <= 1
                  ? null
                  : () => _deleteSelected(s),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
        TextFormField(
          key: ValueKey('pattern_name_${selected.id}_${selected.name}'),
          initialValue: selected.name,
          decoration: const InputDecoration(labelText: 'Pattern Name'),
          onChanged: (v) {
            _replaceSelected(
              s,
              selected.copyWith(name: v.trim().isEmpty ? selected.name : v),
            );
          },
        ),
        const SizedBox(height: 8),
        _SliderRow(
          label: 'Turn ms per degree',
          value: turnMsPerDegree,
          min: 2,
          max: 12,
          divisions: 20,
          onChanged: (v) => _save(s.copyWith(turnMsPerDegree: v)),
          onChangeEnd: (v) => _save(s.copyWith(turnMsPerDegree: v)),
        ),
        const SizedBox(height: 8),
        Text('Pattern steps', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        ...selected.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return _StepEditor(
            step: step,
            index: index,
            isFirst: index == 0,
            isLast: index == selected.steps.length - 1,
            onChanged: (updatedStep) {
              final updatedSteps = [...selected.steps];
              updatedSteps[index] = updatedStep;
              _replaceSelected(s, selected.copyWith(steps: updatedSteps));
            },
            onDelete: () {
              if (selected.steps.length <= 1) return;
              final updatedSteps = [...selected.steps]..removeAt(index);
              _replaceSelected(s, selected.copyWith(steps: updatedSteps));
            },
            onMoveUp: () {
              if (index == 0) return;
              final updatedSteps = [...selected.steps];
              final item = updatedSteps.removeAt(index);
              updatedSteps.insert(index - 1, item);
              _replaceSelected(s, selected.copyWith(steps: updatedSteps));
            },
            onMoveDown: () {
              if (index >= selected.steps.length - 1) return;
              final updatedSteps = [...selected.steps];
              final item = updatedSteps.removeAt(index);
              updatedSteps.insert(index + 1, item);
              _replaceSelected(s, selected.copyWith(steps: updatedSteps));
            },
          );
        }),
        OutlinedButton.icon(
          onPressed: () {
            final updated = selected.copyWith(
              steps: [
                ...selected.steps,
                const MotionPatternStep(
                  kind: MotionStepKind.forward,
                  forwardMs: 900,
                ),
              ],
            );
            _replaceSelected(s, updated);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Step'),
        ),
        const SizedBox(height: 8),
        _SliderRow(
          label: 'Inter-step pause (ms)',
          value: s.interStepPauseMs.toDouble(),
          min: 0,
          max: 600,
          divisions: 30,
          onChanged: (v) => widget.cubit.updateMotionPattern(
            s.copyWith(interStepPauseMs: v.round()),
          ),
          onChangeEnd: (v) => widget.cubit.updateMotionPattern(
            s.copyWith(interStepPauseMs: v.round()),
          ),
        ),
      ],
    );
  }
}

class _StepEditor extends StatelessWidget {
  const _StepEditor({
    required this.step,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.onChanged,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final MotionPatternStep step;
  final int index;
  final bool isFirst;
  final bool isLast;
  final ValueChanged<MotionPatternStep> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Step ${index + 1}'),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: isFirst ? null : onMoveUp,
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: isLast ? null : onMoveDown,
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            DropdownButton<MotionStepKind>(
              value: step.kind,
              isExpanded: true,
              items: MotionStepKind.values
                  .map(
                    (kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(
                        kind == MotionStepKind.forward ? 'Forward' : 'Turn',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                onChanged(step.copyWith(kind: v));
              },
            ),
            if (step.kind == MotionStepKind.forward)
              _SliderRow(
                label: 'Forward duration (ms)',
                value: step.forwardMs.toDouble(),
                min: 200,
                max: 3000,
                divisions: 28,
                onChanged: (v) =>
                    onChanged(step.copyWith(forwardMs: v.round())),
                onChangeEnd: (v) =>
                    onChanged(step.copyWith(forwardMs: v.round())),
              )
            else ...[
              DropdownButton<MotionStepDirection>(
                value: step.turnDirection,
                isExpanded: true,
                items: MotionStepDirection.values
                    .map(
                      (direction) => DropdownMenuItem(
                        value: direction,
                        child: Text(direction.label),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onChanged(step.copyWith(turnDirection: v));
                },
              ),
              _SliderRow(
                label: 'Turn degrees',
                value: step.turnDegrees.toDouble(),
                min: 15,
                max: 360,
                divisions: 23,
                onChanged: (v) =>
                    onChanged(step.copyWith(turnDegrees: v.round())),
                onChangeEnd: (v) =>
                    onChanged(step.copyWith(turnDegrees: v.round())),
              ),
            ],
          ],
        ),
      ),
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
