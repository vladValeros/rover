import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rover_command.dart';
import '../controllers/rover_control_cubit.dart';

class DirectionalPadWidget extends StatelessWidget {
  const DirectionalPadWidget({this.onManualOverride, super.key});

  final VoidCallback? onManualOverride;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DirectionButton(
          icon: Icons.arrow_upward,
          label: 'Forward',
          command: RoverCommand.forward,
          onManualOverride: onManualOverride,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _DirectionButton(
              icon: Icons.arrow_back,
              label: 'Left',
              command: RoverCommand.left,
              onManualOverride: onManualOverride,
            ),
            const SizedBox(width: 8),
            _StopButton(onManualOverride: onManualOverride),
            const SizedBox(width: 8),
            _DirectionButton(
              icon: Icons.arrow_forward,
              label: 'Right',
              command: RoverCommand.right,
              onManualOverride: onManualOverride,
            ),
          ],
        ),
        _DirectionButton(
          icon: Icons.arrow_downward,
          label: 'Backward',
          command: RoverCommand.backward,
          onManualOverride: onManualOverride,
        ),
      ],
    );
  }
}

class _DirectionButton extends StatelessWidget {
  const _DirectionButton({
    required this.icon,
    required this.label,
    required this.command,
    this.onManualOverride,
  });

  final IconData icon;
  final String label;
  final RoverCommand command;
  final VoidCallback? onManualOverride;

  static const double _buttonSize = 80.0;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RoverControlCubit>();
    return GestureDetector(
      onTapDown: (_) {
        onManualOverride?.call();
        cubit.sendCommand(command);
      },
      onTapUp: (_) => cubit.sendCommand(RoverCommand.stop),
      onTapCancel: () => cubit.sendCommand(RoverCommand.stop),
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withAlpha(80),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopButton extends StatelessWidget {
  const _StopButton({this.onManualOverride});

  final VoidCallback? onManualOverride;

  static const double _buttonSize = 80.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onManualOverride?.call();
        context.read<RoverControlCubit>().sendCommand(RoverCommand.stop);
      },
      child: Container(
        width: _buttonSize,
        height: _buttonSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error.withAlpha(40),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.error),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 4),
            Text(
              'Stop',
              style: TextStyle(
                fontSize: 10,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
