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
  late TextEditingController _nameController;
  String _currentPatternId = '';

  // Edit-mode state — null means view mode.
  MotionPatternDefinition? _editDraft;
  bool get _isEditing => _editDraft != null;

  @override
  void initState() {
    super.initState();
    final selected = _selected(widget.settings);
    _currentPatternId = selected.id;
    _nameController = TextEditingController(text: selected.name);
  }

  @override
  void didUpdateWidget(covariant _MotionPatternBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selected(widget.settings);
    if (selected.id != _currentPatternId) {
      // Pattern selection changed — exit edit mode without saving.
      _currentPatternId = selected.id;
      _nameController.text = selected.name;
      setState(() => _editDraft = null);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  MotionPatternDefinition _selected(MotionPatternSettings s) {
    for (final p in s.patterns) {
      if (p.id == s.selectedPatternId) return p;
    }
    return s.patterns.first;
  }

  void _enterEdit(MotionPatternDefinition pattern) {
    _nameController.text = pattern.name;
    setState(() => _editDraft = pattern);
  }

  void _cancelEdit(MotionPatternDefinition saved) {
    _nameController.text = saved.name;
    setState(() => _editDraft = null);
  }

  Future<void> _commitEdit(MotionPatternSettings s) async {
    final draft = _editDraft;
    if (draft == null) return;
    // Flush the current name field value into the draft.
    final name = _nameController.text.trim();
    final finalDraft = name.isEmpty ? draft : draft.copyWith(name: name);
    final patterns = s.patterns
        .map((p) => p.id == finalDraft.id ? finalDraft : p)
        .toList();
    await widget.cubit.updateMotionPattern(s.copyWith(patterns: patterns));
    setState(() => _editDraft = null);
  }

  Future<void> _addPattern(MotionPatternSettings s) async {
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
    final newPattern = MotionPatternDefinition(
      id: id,
      name: 'Custom ${s.patterns.length + 1}',
      steps: const [
        MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
      ],
    );
    await widget.cubit.updateMotionPattern(
      s.copyWith(patterns: [...s.patterns, newPattern], selectedPatternId: id),
    );
    // Immediately enter edit mode for the new pattern.
    _nameController.text = newPattern.name;
    setState(() => _editDraft = newPattern);
    _currentPatternId = id;
  }

  Future<void> _deleteSelected(MotionPatternSettings s) async {
    if (s.patterns.length <= 1) return;
    final remaining = s.patterns
        .where((p) => p.id != s.selectedPatternId)
        .toList();
    setState(() => _editDraft = null);
    await widget.cubit.updateMotionPattern(
      s.copyWith(patterns: remaining, selectedPatternId: remaining.first.id),
    );
  }

  void _updateDraftStep(int index, MotionPatternStep updated) {
    if (_editDraft == null) return;
    final steps = [..._editDraft!.steps];
    steps[index] = updated;
    setState(() => _editDraft = _editDraft!.copyWith(steps: steps));
  }

  void _deleteDraftStep(int index) {
    if (_editDraft == null || _editDraft!.steps.length <= 1) return;
    final steps = [..._editDraft!.steps]..removeAt(index);
    setState(() => _editDraft = _editDraft!.copyWith(steps: steps));
  }

  void _moveDraftStep(int index, int delta) {
    if (_editDraft == null) return;
    final newIndex = index + delta;
    if (newIndex < 0 || newIndex >= _editDraft!.steps.length) return;
    final steps = [..._editDraft!.steps];
    final item = steps.removeAt(index);
    steps.insert(newIndex, item);
    setState(() => _editDraft = _editDraft!.copyWith(steps: steps));
  }

  void _addDraftStep() {
    if (_editDraft == null) return;
    setState(
      () => _editDraft = _editDraft!.copyWith(
        steps: [
          ..._editDraft!.steps,
          const MotionPatternStep(kind: MotionStepKind.forward, forwardMs: 900),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.settings;
    final saved = _selected(s);
    // In edit mode use the draft, otherwise use the saved pattern.
    final display = _isEditing ? _editDraft! : saved;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Pattern selector + add/delete ─────────────────────────────────
        Row(
          children: [
            Expanded(
              child: DropdownButton<String>(
                value: saved.id,
                isExpanded: true,
                // Disable switching while editing to avoid losing unsaved work.
                items: s.patterns
                    .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern.id,
                        child: Text(pattern.name),
                      ),
                    )
                    .toList(),
                onChanged: _isEditing
                    ? null
                    : (v) {
                        if (v == null) return;
                        widget.cubit.updateMotionPattern(
                          s.copyWith(selectedPatternId: v),
                        );
                      },
              ),
            ),
            IconButton(
              tooltip: 'New Pattern',
              onPressed: _isEditing ? null : () => _addPattern(s),
              icon: const Icon(Icons.add_circle_outline),
            ),
            IconButton(
              tooltip: 'Delete Pattern',
              onPressed: (_isEditing || s.patterns.length <= 1)
                  ? null
                  : () => _deleteSelected(s),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // ── Edit / Save / Cancel header ───────────────────────────────────
        if (!_isEditing)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _enterEdit(saved),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit Pattern'),
            ),
          )
        else ...[
          // Pattern name field — only visible in edit mode.
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Pattern Name',
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Global timing sliders (always visible, save immediately) ──────
        _SliderRow(
          label: 'Turn ms per degree',
          value: s.turnMsPerDegree,
          min: 2,
          max: 12,
          divisions: 20,
          onChanged: (v) =>
              widget.cubit.updateMotionPattern(s.copyWith(turnMsPerDegree: v)),
          onChangeEnd: (v) =>
              widget.cubit.updateMotionPattern(s.copyWith(turnMsPerDegree: v)),
        ),
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

        // ── Step list ─────────────────────────────────────────────────────
        const SizedBox(height: 8),
        Text('Steps', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),

        ...display.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return _StepEditor(
            step: step,
            index: index,
            isFirst: index == 0,
            isLast: index == display.steps.length - 1,
            readOnly: !_isEditing,
            onChanged: (updated) => _updateDraftStep(index, updated),
            onDelete: () => _deleteDraftStep(index),
            onMoveUp: () => _moveDraftStep(index, -1),
            onMoveDown: () => _moveDraftStep(index, 1),
          );
        }),

        if (_isEditing) ...[
          OutlinedButton.icon(
            onPressed: _addDraftStep,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Step'),
          ),
          const SizedBox(height: 16),
          // ── Save / Cancel bar ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _commitEdit(s),
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _cancelEdit(saved),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: cs.error,
                    side: BorderSide(color: cs.error),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
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
    required this.readOnly,
    required this.onChanged,
    required this.onDelete,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  final MotionPatternStep step;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool readOnly;
  final ValueChanged<MotionPatternStep> onChanged;
  final VoidCallback onDelete;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    // Read-only: compact summary row, no controls.
    if (readOnly) {
      final kindLabel = step.kind == MotionStepKind.forward
          ? 'Forward'
          : 'Turn';
      final detail = step.kind == MotionStepKind.forward
          ? '${step.forwardMs} ms'
          : '${step.turnDirection.label} ${step.turnDegrees}°';
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Text('${index + 1}', style: tt.labelSmall),
            ),
            const SizedBox(width: 8),
            Text(kindLabel, style: tt.bodyMedium),
            const SizedBox(width: 6),
            Text(
              detail,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

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
