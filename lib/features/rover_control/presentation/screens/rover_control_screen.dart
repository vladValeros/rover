import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/locator.dart';
import '../../../connection/connection_routes.dart';
import '../controllers/rover_control_cubit.dart';
import '../controllers/rover_control_state.dart';
import '../widgets/directional_pad_widget.dart';
import '../widgets/led_control_widget.dart';
import '../widgets/rover_stream_viewer_widget.dart';

class RoverControlScreen extends StatefulWidget {
  const RoverControlScreen({super.key});

  @override
  State<RoverControlScreen> createState() => _RoverControlScreenState();
}

class _RoverControlScreenState extends State<RoverControlScreen> {
  StreamOrientationMode _orientationMode = StreamOrientationMode.normal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<RoverControlCubit>(),
      child: BlocListener<RoverControlCubit, RoverControlState>(
        listener: (context, state) {
          state.whenOrNull(
            failure: (message) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            },
          );
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Rover Control'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.wifi_off),
                tooltip: 'Disconnect',
                onPressed: () => context.go(ConnectionRoutes.path),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RoverStreamViewerWidget(orientationMode: _orientationMode),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Normal'),
                        selected:
                            _orientationMode == StreamOrientationMode.normal,
                        onSelected: (_) {
                          setState(
                            () =>
                                _orientationMode = StreamOrientationMode.normal,
                          );
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Rotate 180'),
                        selected:
                            _orientationMode == StreamOrientationMode.rotate180,
                        onSelected: (_) {
                          setState(
                            () => _orientationMode =
                                StreamOrientationMode.rotate180,
                          );
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Rotate 180 + Mirror'),
                        selected:
                            _orientationMode ==
                            StreamOrientationMode.rotate180Mirrored,
                        onSelected: (_) {
                          setState(
                            () => _orientationMode =
                                StreamOrientationMode.rotate180Mirrored,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const DirectionalPadWidget(),
                  const SizedBox(height: 16),
                  const LedControlWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
