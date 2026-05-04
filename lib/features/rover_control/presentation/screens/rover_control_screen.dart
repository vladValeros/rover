import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/locator.dart';
import '../../../connection/connection_routes.dart';
import '../../../ml_motion_patterns/data/services/motion_pattern_runner.dart';
import '../../../ml_motion_patterns/domain/entities/motion_pattern_settings.dart';
import '../../../ml_motion_patterns/domain/enums/motion_pattern_type.dart';
import '../../../ml_object_detection/domain/enums/object_detection_mode.dart';
import '../../../ml_settings/ml_settings_routes.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_cubit.dart';
import '../../../ml_settings/presentation/controllers/ml_settings_state.dart';
import '../controllers/rover_control_cubit.dart';
import '../controllers/rover_control_state.dart';
import '../../domain/entities/rover_command.dart';
import '../widgets/directional_pad_widget.dart';
import '../widgets/led_control_widget.dart';
import '../widgets/rover_stream_viewer_widget.dart';

class RoverControlScreen extends StatefulWidget {
  const RoverControlScreen({super.key});

  @override
  State<RoverControlScreen> createState() => _RoverControlScreenState();
}

class _RoverControlScreenState extends State<RoverControlScreen>
    with WidgetsBindingObserver {
  StreamOrientationMode _orientationMode = StreamOrientationMode.normal;
  int _streamRefreshNonce = 0;
  bool _offlineSheetShown = false;
  final MotionPatternRunner _motionPatternRunner = MotionPatternRunner();
  bool _isMotionPatternRunning = false;
  String _motionPatternStep = 'Idle';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _motionPatternRunner.stop();
      if (mounted) {
        setState(() {
          _isMotionPatternRunning = false;
          _motionPatternStep = 'Idle';
        });
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motionPatternRunner.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<RoverControlCubit>(),
      child: BlocListener<RoverControlCubit, RoverControlState>(
        listener: (context, state) {
          state.whenOrNull(
            failure: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  action: SnackBarAction(
                    label: 'Dismiss',
                    onPressed: () =>
                        ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                  ),
                ),
              );
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
                icon: const Icon(Icons.settings),
                tooltip: 'ML / AI Settings',
                onPressed: () => context.push(MlSettingsRoutes.path),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Connection',
                onPressed: () {
                  setState(() {
                    _streamRefreshNonce++;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Refreshing rover connection...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.wifi_off),
                tooltip: 'Disconnect',
                onPressed: () {
                  _stopMotionPattern(context, sendStopCommand: true);
                  context.go(ConnectionRoutes.path);
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BlocBuilder<MlSettingsCubit, MlSettingsState>(
                builder: (context, mlState) {
                  final mlSettings = mlState.whenOrNull(loaded: (s) => s);
                  final od = mlSettings?.objectDetection;
                  return Column(
                    children: [
                      RoverStreamViewerWidget(
                        orientationMode: _orientationMode,
                        detectionMode: od?.mode ?? ObjectDetectionMode.off,
                        detectionConfidenceThreshold:
                            od?.confidenceThreshold ?? 0.45,
                        detectionIntervalMs: od?.intervalMs ?? 800,
                        showDiagnostics: od?.showDiagnostics ?? true,
                        onMlUnavailable: (message) {
                          final cubit = context.read<MlSettingsCubit>();
                          final current = cubit.state.whenOrNull(
                            loaded: (s) => s,
                          );
                          if (current != null) {
                            cubit.updateObjectDetection(
                              current.objectDetection.copyWith(
                                mode: ObjectDetectionMode.off,
                              ),
                            );
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(message)));
                        },
                        refreshNonce: _streamRefreshNonce,
                        onRoverOffline: () => _showOfflineSheet(context),
                      ),
                      const SizedBox(height: 10),
                      // ── Camera orientation chips ─────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('Normal'),
                            selected:
                                _orientationMode ==
                                StreamOrientationMode.normal,
                            onSelected: (_) => setState(
                              () => _orientationMode =
                                  StreamOrientationMode.normal,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Rotate 180'),
                            selected:
                                _orientationMode ==
                                StreamOrientationMode.rotate180,
                            onSelected: (_) => setState(
                              () => _orientationMode =
                                  StreamOrientationMode.rotate180,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Rotate 180 + Mirror'),
                            selected:
                                _orientationMode ==
                                StreamOrientationMode.rotate180Mirrored,
                            onSelected: (_) => setState(
                              () => _orientationMode =
                                  StreamOrientationMode.rotate180Mirrored,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // ── Motion pattern quick-start (near D-pad) ──────────
                      _MotionPatternRuntimeCard(
                        settings: mlSettings?.motionPattern,
                        isRunning: _isMotionPatternRunning,
                        stepLabel: _motionPatternStep,
                        onStart: () {
                          final settings = mlSettings?.motionPattern;
                          if (settings == null || !settings.enabled) return;
                          _startMotionPattern(context, settings);
                        },
                        onStop: () =>
                            _stopMotionPattern(context, sendStopCommand: true),
                      ),
                      const SizedBox(height: 16),
                      DirectionalPadWidget(
                        onManualOverride: _onManualControlOverride,
                      ),
                      const SizedBox(height: 16),
                      const LedControlWidget(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showOfflineSheet(BuildContext context) {
    if (_offlineSheetShown) return;
    _offlineSheetShown = true;

    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (sheetCtx) => _RoverOfflineSheet(
        onRetry: () {
          _stopMotionPattern(context, sendStopCommand: true);
          Navigator.of(sheetCtx).pop();
          setState(() => _streamRefreshNonce++);
        },
        onGoBack: () {
          _stopMotionPattern(context, sendStopCommand: true);
          Navigator.of(sheetCtx).pop();
          context.go(ConnectionRoutes.path);
        },
      ),
    ).whenComplete(() {
      if (mounted) _offlineSheetShown = false;
    });
  }

  void _onManualControlOverride() {
    if (!_isMotionPatternRunning) return;
    _motionPatternRunner.stop();
    if (mounted) {
      setState(() {
        _isMotionPatternRunning = false;
        _motionPatternStep = 'Manual override';
      });
    }
  }

  void _startMotionPattern(
    BuildContext context,
    MotionPatternSettings settings,
  ) {
    if (_isMotionPatternRunning || !settings.enabled) return;
    final cubit = context.read<RoverControlCubit>();
    setState(() {
      _isMotionPatternRunning = true;
      _motionPatternStep = 'Starting ${settings.pattern.label}';
    });

    unawaited(
      _motionPatternRunner
          .start(
            settings: settings,
            sendCommand: cubit.sendCommand,
            onStep: (stepLabel) {
              if (!mounted) return;
              setState(() => _motionPatternStep = stepLabel);
            },
          )
          .whenComplete(() {
            if (!mounted) return;
            setState(() {
              _isMotionPatternRunning = false;
              if (_motionPatternStep != 'Manual override') {
                _motionPatternStep = 'Idle';
              }
            });
          }),
    );
  }

  void _stopMotionPattern(
    BuildContext context, {
    required bool sendStopCommand,
  }) {
    if (!_isMotionPatternRunning && !_motionPatternRunner.isRunning) return;
    _motionPatternRunner.stop();
    if (sendStopCommand) {
      unawaited(
        context.read<RoverControlCubit>().sendCommand(RoverCommand.stop),
      );
    }
    if (mounted) {
      setState(() {
        _isMotionPatternRunning = false;
        _motionPatternStep = 'Idle';
      });
    }
  }
}

class _MotionPatternRuntimeCard extends StatelessWidget {
  const _MotionPatternRuntimeCard({
    required this.settings,
    required this.isRunning,
    required this.stepLabel,
    required this.onStart,
    required this.onStop,
  });

  final MotionPatternSettings? settings;
  final bool isRunning;
  final String stepLabel;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isEnabled = settings?.enabled ?? false;
    final patternLabel = settings?.pattern.label ?? 'Unknown';

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text('Motion Pattern AI', style: tt.titleSmall),
                const Spacer(),
                _StatePill(isRunning: isRunning, enabled: isEnabled),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isEnabled
                  ? 'Pattern: $patternLabel | Step: $stepLabel'
                  : 'Enable Motion Patterns from ML Settings first.',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isEnabled && !isRunning ? onStart : null,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Pattern'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isRunning ? onStop : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop Pattern'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.isRunning, required this.enabled});

  final bool isRunning;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final String label = !enabled
        ? 'Disabled'
        : (isRunning ? 'Running' : 'Ready');
    final Color bg = !enabled
        ? cs.surfaceContainerHighest
        : (isRunning ? cs.primaryContainer : cs.tertiaryContainer);
    final Color fg = !enabled
        ? cs.onSurfaceVariant
        : (isRunning ? cs.onPrimaryContainer : cs.onTertiaryContainer);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg),
      ),
    );
  }
}

class _RoverOfflineSheet extends StatelessWidget {
  const _RoverOfflineSheet({required this.onRetry, required this.onGoBack});

  final VoidCallback onRetry;
  final VoidCallback onGoBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: cs.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Icon(Icons.power_off_rounded, size: 48, color: cs.onSurfaceVariant),
          const SizedBox(height: 12),
          Text('Rover is offline', style: tt.titleLarge),
          const SizedBox(height: 8),
          Text(
            'The rover stopped responding. It may have been powered off or lost network connection.',
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry Connection'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onGoBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to Menu'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ],
      ),
    );
  }
}
