import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/rover_command.dart';
import '../controllers/rover_control_cubit.dart';

class LedControlWidget extends StatelessWidget {
  const LedControlWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.read<RoverControlCubit>().sendCommand(
              RoverCommand.ledOn,
            ),
            icon: const Icon(Icons.lightbulb),
            label: const Text('Light ON'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.yellow,
              side: const BorderSide(color: Colors.yellow),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.read<RoverControlCubit>().sendCommand(
              RoverCommand.ledOff,
            ),
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Light OFF'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
