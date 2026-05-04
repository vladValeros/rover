import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _modeKey = 'ml_mode';
  static const String _thresholdKey = 'ml_threshold';
  static const String _intervalKey = 'ml_interval_ms';
  static const String _showDiagnosticsKey = 'ml_show_diagnostics';

  StreamOrientationMode _orientationMode = StreamOrientationMode.normal;
  ObjectDetectionMode _detectionMode = ObjectDetectionMode.off;
  int _streamRefreshNonce = 0;
  double _confidenceThreshold = 0.45;
  int _detectionIntervalMs = 800;
  bool _showDiagnostics = true;

  @override
  void initState() {
    super.initState();
    _loadMlPreferences();
  }

  Future<void> _loadMlPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _detectionMode = ObjectDetectionMode.values[prefs.getInt(_modeKey) ?? 0];
      _confidenceThreshold = prefs.getDouble(_thresholdKey) ?? 0.45;
      _detectionIntervalMs = prefs.getInt(_intervalKey) ?? 800;
      _showDiagnostics = prefs.getBool(_showDiagnosticsKey) ?? true;
    });
  }

  Future<void> _saveMlPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_modeKey, _detectionMode.index);
    await prefs.setDouble(_thresholdKey, _confidenceThreshold);
    await prefs.setInt(_intervalKey, _detectionIntervalMs);
    await prefs.setBool(_showDiagnosticsKey, _showDiagnostics);
  }

  Future<void> _setDetectionMode(ObjectDetectionMode mode) async {
    if (_detectionMode == mode) {
      return;
    }
    setState(() {
      _detectionMode = mode;
    });
    await _saveMlPreferences();
  }

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
                onPressed: () => context.go(ConnectionRoutes.path),
              ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  RoverStreamViewerWidget(
                    orientationMode: _orientationMode,
                    detectionMode: _detectionMode,
                    detectionConfidenceThreshold: _confidenceThreshold,
                    detectionIntervalMs: _detectionIntervalMs,
                    showDiagnostics: _showDiagnostics,
                    onMlUnavailable: (message) {
                      _setDetectionMode(ObjectDetectionMode.off);
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(message)));
                    },
                    refreshNonce: _streamRefreshNonce,
                  ),
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
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('ML Off'),
                        selected: _detectionMode == ObjectDetectionMode.off,
                        onSelected: (_) {
                          _setDetectionMode(ObjectDetectionMode.off);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('General'),
                        selected: _detectionMode == ObjectDetectionMode.general,
                        onSelected: (_) {
                          _setDetectionMode(ObjectDetectionMode.general);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Person'),
                        selected:
                            _detectionMode == ObjectDetectionMode.personOnly,
                        onSelected: (_) {
                          _setDetectionMode(ObjectDetectionMode.personOnly);
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Vehicle'),
                        selected:
                            _detectionMode == ObjectDetectionMode.vehicleOnly,
                        onSelected: (_) {
                          _setDetectionMode(ObjectDetectionMode.vehicleOnly);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Confidence'),
                      Expanded(
                        child: Slider(
                          value: _confidenceThreshold,
                          min: 0.1,
                          max: 0.95,
                          divisions: 17,
                          label: _confidenceThreshold.toStringAsFixed(2),
                          onChanged: (value) {
                            setState(() {
                              _confidenceThreshold = value;
                            });
                          },
                          onChangeEnd: (_) => _saveMlPreferences(),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Detection Rate'),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: _detectionIntervalMs,
                        items: const [
                          DropdownMenuItem(value: 300, child: Text('Fast')),
                          DropdownMenuItem(
                            value: 800,
                            child: Text('Balanced'),
                          ),
                          DropdownMenuItem(
                            value: 1500,
                            child: Text('Power Save'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            _detectionIntervalMs = value;
                          });
                          _saveMlPreferences();
                        },
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Text('Diagnostics'),
                          Switch(
                            value: _showDiagnostics,
                            onChanged: (value) {
                              setState(() {
                                _showDiagnostics = value;
                              });
                              _saveMlPreferences();
                            },
                          ),
                        ],
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
