import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../rover_control/rover_control_routes.dart';
import '../controllers/connection_cubit.dart';
import '../controllers/connection_state.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController _ipController = TextEditingController(
    text: AppConstants.defaultRoverIp,
  );
  String? _errorMessage;

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectionCubit, RoverConnectionState>(
      listener: (context, state) {
        state.whenOrNull(
          loaded: (connection) {
            locator<DioClient>().updateBaseUrl(connection.roverIpAddress);
            context.go(RoverControlRoutes.path);
          },
          saved: (connection) {
            locator<DioClient>().updateBaseUrl(connection.roverIpAddress);
            context.go(RoverControlRoutes.path);
          },
          testing: () => setState(() => _errorMessage = null),
          loading: () => setState(() => _errorMessage = null),
          testSuccess: () {
            setState(() => _errorMessage = null);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Rover reachable! Tap Connect to proceed.'),
                backgroundColor: Colors.green,
              ),
            );
          },
          discovered: (ipAddress) {
            setState(() {
              _errorMessage = null;
              _ipController.text = ipAddress;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Rover found at $ipAddress'),
                backgroundColor: Colors.green,
              ),
            );
          },
          discovering: () => setState(() => _errorMessage = null),
          failure: (message) => setState(() => _errorMessage = message),
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rover Control',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Enter the rover's IP address",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(180),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'Rover IP Address',
                    hintText: '192.168.4.1',
                    prefixIcon: Icon(Icons.wifi),
                  ),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 16),
                BlocBuilder<ConnectionCubit, RoverConnectionState>(
                  builder: (context, state) {
                    final bool isBusy = state.maybeWhen(
                      loading: () => true,
                      testing: () => true,
                      discovering: () => true,
                      orElse: () => false,
                    );
                    final bool isTesting = state.maybeWhen(
                      testing: () => true,
                      orElse: () => false,
                    );
                    final bool isDiscovering = state.maybeWhen(
                      discovering: () => true,
                      orElse: () => false,
                    );
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        OutlinedButton.icon(
                          onPressed: isBusy
                              ? null
                              : () => context
                                    .read<ConnectionCubit>()
                                    .discoverRoverIp(),
                          icon: isDiscovering
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search),
                          label: const Text('Auto Detect Rover'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: isBusy
                              ? null
                              : () => context
                                    .read<ConnectionCubit>()
                                    .testConnection(_ipController.text.trim()),
                          child: isTesting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Test Connection'),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: isBusy
                              ? null
                              : () => context
                                    .read<ConnectionCubit>()
                                    .saveConnection(_ipController.text.trim()),
                          child: isBusy && !isTesting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Connect'),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: isBusy
                              ? null
                              : () {
                                  final ip = _ipController.text.trim();
                                  locator<DioClient>().updateBaseUrl(ip);
                                  context.go(RoverControlRoutes.path);
                                },
                          icon: const Icon(Icons.developer_mode_outlined),
                          label: const Text('Open Controller (Offline)'),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Use this for UI testing without rover connection. '
                          'Stream and controls will show connection errors gracefully.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(180),
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
