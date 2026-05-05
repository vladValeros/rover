import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/locator.dart';
import '../../../connection/connection_routes.dart';
import '../../../ml_motion_patterns/data/services/motion_pattern_runner.dart';
import '../../../ml_motion_patterns/domain/entities/motion_pattern_settings.dart';
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
  const RoverControlScreen({this.isPreviewMode = false, super.key});

  final bool isPreviewMode;

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
  late final RoverControlCubit _roverCubit;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _roverCubit = locator<RoverControlCubit>();
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
    _roverCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _roverCubit,
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
                  _stopMotionPatternDirect(sendStopCommand: true);
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
                  final mpSettings = mlSettings?.motionPattern;
                  if (widget.isPreviewMode) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              children: [
                                _PreviewStreamFrame(
                                  onBackToMenu: () =>
                                      context.go(ConnectionRoutes.path),
                                ),
                                const SizedBox(height: 10),
                                _buildMotionPatternSection(mpSettings),
                                const SizedBox(height: 12),
                                IgnorePointer(
                                  ignoring: true,
                                  child: Opacity(
                                    opacity: 0.6,
                                    child: const LedControlWidget(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildControlPanel(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  }

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
                      _buildMotionPatternSection(mpSettings),
                      const SizedBox(height: 12),
                      const LedControlWidget(),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: _buildControlPanel(),
                        ),
                      ),
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
          _stopMotionPatternDirect(sendStopCommand: true);
          Navigator.of(sheetCtx).pop();
          setState(() => _streamRefreshNonce++);
        },
        onGoBack: () {
          _stopMotionPatternDirect(sendStopCommand: true);
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

  void _startMotionPattern(MotionPatternSettings settings) {
    if (_isMotionPatternRunning || !settings.enabled) return;
    final selectedPattern = settings.patterns.firstWhere(
      (p) => p.id == settings.selectedPatternId,
      orElse: () => settings.patterns.first,
    );
    setState(() {
      _isMotionPatternRunning = true;
      _motionPatternStep = 'Starting ${selectedPattern.name}';
    });

    unawaited(
      _motionPatternRunner
          .start(
            settings: settings,
            sendCommand: _roverCubit.sendCommand,
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

  void _stopMotionPatternDirect({required bool sendStopCommand}) {
    if (!_isMotionPatternRunning && !_motionPatternRunner.isRunning) return;
    _motionPatternRunner.stop();
    if (sendStopCommand) {
      unawaited(_roverCubit.sendCommand(RoverCommand.stop));
    }
    if (mounted) {
      setState(() {
        _isMotionPatternRunning = false;
        _motionPatternStep = 'Idle';
      });
    }
  }

  Widget _buildMotionPatternSection(MotionPatternSettings? motionSettings) {
    final isMotionFeatureEnabled = motionSettings?.enabled ?? false;
    if (!isMotionFeatureEnabled || motionSettings == null) {
      return const SizedBox.shrink();
    }

    final card = _MotionPatternRuntimeCard(
      settings: motionSettings,
      isRunning: _isMotionPatternRunning,
      stepLabel: _motionPatternStep,
      canControl: !widget.isPreviewMode,
      onPatternChanged: (patternId) {
        context.read<MlSettingsCubit>().updateMotionPattern(
          motionSettings.copyWith(selectedPatternId: patternId),
        );
      },
      onStart: () {
        if (widget.isPreviewMode) return;
        _startMotionPattern(motionSettings);
      },
      onStop: () => _stopMotionPatternDirect(sendStopCommand: true),
    );

    if (!widget.isPreviewMode) return card;

    return Opacity(opacity: 0.85, child: card);
  }

  Widget _buildControlPanel() {
    return Column(
      children: [
        IgnorePointer(
          ignoring: widget.isPreviewMode,
          child: Opacity(
            opacity: widget.isPreviewMode ? 0.6 : 1,
            child: DirectionalPadWidget(
              onManualOverride: _onManualControlOverride,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MotionPatternRuntimeCard extends StatelessWidget {
  const _MotionPatternRuntimeCard({
    required this.settings,
    required this.isRunning,
    required this.stepLabel,
    required this.canControl,
    required this.onPatternChanged,
    required this.onStart,
    required this.onStop,
  });

  final MotionPatternSettings settings;
  final bool isRunning;
  final String stepLabel;
  final bool canControl;
  final ValueChanged<String> onPatternChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final selectedPattern = settings.patterns.firstWhere(
      (p) => p.id == settings.selectedPatternId,
      orElse: () => settings.patterns.first,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.route, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<String>(
                value: selectedPattern.id,
                isExpanded: true,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: settings.patterns
                    .map(
                      (pattern) => DropdownMenuItem(
                        value: pattern.id,
                        child: Text(
                          pattern.name,
                          overflow: TextOverflow.ellipsis,
                          style: tt.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: isRunning
                    ? null
                    : (value) {
                        if (value == null) return;
                        onPatternChanged(value);
                      },
              ),
            ),
            const SizedBox(width: 8),
            _StatePill(isRunning: isRunning, enabled: true),
            const SizedBox(width: 8),
            FilledButton.tonalIcon(
              onPressed: (!isRunning && canControl) ? onStart : null,
              icon: const Icon(Icons.play_arrow, size: 16),
              label: const Text('Start'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
            const SizedBox(width: 6),
            OutlinedButton.icon(
              onPressed: (isRunning && canControl) ? onStop : null,
              icon: const Icon(Icons.stop, size: 14),
              label: const Text('Stop'),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStreamFrame extends StatelessWidget {
  const _PreviewStreamFrame({required this.onBackToMenu});

  final VoidCallback onBackToMenu;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded, color: cs.error, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Rover disconnected',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Preview mode: stream disabled',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: OutlinedButton.icon(
                onPressed: onBackToMenu,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Menu'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                ),
              ),
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
