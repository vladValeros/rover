import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app/locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../ml_settings/domain/enums/object_detection_mode.dart';
import '../services/object_detection_service.dart';

export '../../../ml_settings/domain/enums/object_detection_mode.dart';

enum StreamOrientationMode { normal, rotate180, rotate180Mirrored }

class DetectionOverlayBox {
  const DetectionOverlayBox({
    required this.normalizedRect,
    required this.label,
    required this.confidence,
  });

  final Rect normalizedRect;
  final String label;
  final double confidence;
}

class RoverStreamViewerWidget extends StatefulWidget {
  const RoverStreamViewerWidget({
    required this.orientationMode,
    required this.detectionMode,
    this.refreshNonce = 0,
    this.detectionConfidenceThreshold = 0.45,
    this.detectionIntervalMs = 800,
    this.minDetectionArea = 0.002,
    this.showDiagnostics = true,
    this.onMlUnavailable,
    super.key,
  });

  final StreamOrientationMode orientationMode;
  final ObjectDetectionMode detectionMode;
  final int refreshNonce;
  final double detectionConfidenceThreshold;
  final int detectionIntervalMs;
  final double minDetectionArea;
  final bool showDiagnostics;
  final ValueChanged<String>? onMlUnavailable;

  @override
  State<RoverStreamViewerWidget> createState() =>
      _RoverStreamViewerWidgetState();
}

class _RoverStreamViewerWidgetState extends State<RoverStreamViewerWidget> {
  static const Duration _watchdogInterval = Duration(seconds: 2);
  static const Duration _freezeThreshold = Duration(seconds: 6);
  static const Duration _autoReconnectDelay = Duration(seconds: 1);
  static const Duration _streamConnectTimeout = Duration(seconds: 20);

  Uint8List? _currentFrame;
  StreamSubscription<Uint8List>? _streamSubscription;
  bool _hasError = false;
  String? _errorMessage;
  String? _streamEndpoint;
  CancelToken? _cancelToken;
  Timer? _watchdogTimer;
  Timer? _reconnectTimer;
  DateTime? _lastFrameAt;
  DateTime? _lastInferenceAt;
  bool _isStarting = false;
  bool _isDetecting = false;
  List<DetectionOverlayBox> _detections = const [];
  int _lastInferenceMs = 0;
  String? _detectionError;
  bool _mlUnavailable = false;
  int _processedInferenceCount = 0;
  int _skippedInferenceCount = 0;
  int _totalInferenceMs = 0;
  int _reconnectCount = 0;
  final ObjectDetectionService _detectionService = ObjectDetectionService();

  @override
  void initState() {
    super.initState();
    _watchdogTimer = Timer.periodic(_watchdogInterval, (_) {
      _checkForFreeze();
    });
    _startStream();
  }

  @override
  void didUpdateWidget(covariant RoverStreamViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshNonce != oldWidget.refreshNonce) {
      _restartStream('Manual refresh requested');
    }
    if (widget.detectionMode != oldWidget.detectionMode &&
        widget.detectionMode == ObjectDetectionMode.off) {
      setState(() {
        _detections = const [];
        _detectionError = null;
      });
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _streamSubscription?.cancel();
    _watchdogTimer?.cancel();
    _reconnectTimer?.cancel();
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _startStream() async {
    if (_isStarting) {
      return;
    }
    _isStarting = true;

    _reconnectTimer?.cancel();
    _cancelToken?.cancel();
    await _streamSubscription?.cancel();

    setState(() {
      _hasError = false;
      _currentFrame = null;
      _errorMessage = null;
      _lastFrameAt = null;
    });

    try {
      _cancelToken = CancelToken();
      final dio = locator<DioClient>().dio;
      final baseUrl = dio.options.baseUrl;
      final fallbackBaseUrl =
          'http://${AppConstants.defaultRoverIp}:${AppConstants.controlPort}';
      final controlUri = Uri.parse(baseUrl.isEmpty ? fallbackBaseUrl : baseUrl);
      final streamUri = controlUri.replace(
        port: AppConstants.streamPort,
        path: '/stream',
      );

      _streamEndpoint = streamUri.toString();

      final streamDio = Dio(
        BaseOptions(
          connectTimeout: _streamConnectTimeout,
          sendTimeout: _streamConnectTimeout,
          receiveTimeout: const Duration(minutes: 5),
          responseType: ResponseType.stream,
          headers: const {'Accept': 'multipart/x-mixed-replace'},
        ),
      );

      final response = await streamDio.getUri<ResponseBody>(
        streamUri,
        cancelToken: _cancelToken,
      );

      final stream = response.data!.stream;
      final List<int> buffer = [];

      _streamSubscription = stream
          .map((chunk) => chunk)
          .listen(
            (chunk) {
              buffer.addAll(chunk);
              _extractFrames(buffer);
            },
            onError: (error) {
              _onStreamFailure(error.toString());
            },
            onDone: () {
              _onStreamFailure('Stream ended unexpectedly. Reconnecting...');
            },
            cancelOnError: true,
          );
    } on DioException catch (e) {
      _onStreamFailure(e.message ?? e.type.name);
    } catch (e) {
      _onStreamFailure(e.toString());
    } finally {
      _isStarting = false;
    }
  }

  void _extractFrames(List<int> buffer) {
    int startIndex = -1;

    for (int i = 0; i < buffer.length - 1; i++) {
      if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
        startIndex = i;
      }
      if (startIndex != -1 &&
          buffer[i] == 0xFF &&
          buffer[i + 1] == 0xD9 &&
          i > startIndex) {
        final frame = Uint8List.fromList(buffer.sublist(startIndex, i + 2));
        buffer.removeRange(0, i + 2);
        if (mounted) {
          setState(() {
            _currentFrame = frame;
            _lastFrameAt = DateTime.now();
            if (_hasError) {
              _hasError = false;
              _errorMessage = null;
            }
          });
        }
        _runDetectionIfNeeded(frame);
        return;
      }
    }
  }

  Future<void> _runDetectionIfNeeded(Uint8List frame) async {
    if (widget.detectionMode == ObjectDetectionMode.off ||
        _isDetecting ||
        _mlUnavailable) {
      return;
    }

    final now = DateTime.now();
    final lastInferenceAt = _lastInferenceAt;
    final interval = Duration(milliseconds: widget.detectionIntervalMs);
    if (lastInferenceAt != null && now.difference(lastInferenceAt) < interval) {
      _skippedInferenceCount++;
      return;
    }

    _isDetecting = true;
    _lastInferenceAt = now;

    final watch = Stopwatch()..start();
    try {
      final rawDetections = await _detectionService.detect(
        frame,
        confidenceThreshold: widget.detectionConfidenceThreshold,
      );

      if (_detectionService.isUnavailable) {
        const message =
            'ML plugin not available in current runtime. '
            'Stop app and run full rebuild (flutter clean; flutter run).';
        _disableMlForSession('detector', message);
        return;
      }

      final mapped = <DetectionOverlayBox>[];
      for (final detection in rawDetections) {
        final label = _normalizeLabel(detection.label);
        if (!_shouldIncludeLabel(label)) {
          continue;
        }

        final area =
            detection.normalizedRect.width * detection.normalizedRect.height;
        if (area < widget.minDetectionArea) {
          continue;
        }

        mapped.add(
          DetectionOverlayBox(
            normalizedRect: detection.normalizedRect,
            label: label,
            confidence: detection.confidence,
          ),
        );
      }

      if (mounted) {
        setState(() {
          _detections = mapped;
          _detectionError = null;
        });
      }
    } catch (e) {
      _logError('detector', e.toString());
      if (mounted) {
        setState(() {
          _detectionError = e.toString();
        });
      }
    } finally {
      watch.stop();
      if (mounted) {
        setState(() {
          _lastInferenceMs = watch.elapsedMilliseconds;
          _processedInferenceCount++;
          _totalInferenceMs += watch.elapsedMilliseconds;
        });
      }
      _isDetecting = false;
    }
  }

  bool _shouldIncludeLabel(String label) {
    final lower = label.toLowerCase();
    switch (widget.detectionMode) {
      case ObjectDetectionMode.off:
        return false;
      case ObjectDetectionMode.general:
        return true;
      case ObjectDetectionMode.personOnly:
        return lower.contains('person') || lower.contains('human');
      case ObjectDetectionMode.vehicleOnly:
        return lower.contains('car') ||
            lower.contains('vehicle') ||
            lower.contains('truck') ||
            lower.contains('bus') ||
            lower.contains('motorcycle') ||
            lower.contains('bike');
    }
  }

  void _checkForFreeze() {
    if (!mounted || _hasError || _currentFrame == null || _isStarting) {
      return;
    }

    final lastFrameAt = _lastFrameAt;
    if (lastFrameAt == null) {
      return;
    }

    final elapsed = DateTime.now().difference(lastFrameAt);
    if (elapsed > _freezeThreshold) {
      _restartStream('Stream frozen. Reconnecting...');
    }
  }

  void _onStreamFailure(String message) {
    _logError('stream', message);
    if (!mounted) {
      return;
    }
    setState(() {
      _hasError = true;
      _errorMessage = message;
    });
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_autoReconnectDelay, () {
      if (mounted) {
        _reconnectCount++;
        _startStream();
      }
    });
  }

  void _restartStream(String reason) {
    if (!mounted) {
      return;
    }
    setState(() {
      _hasError = true;
      _errorMessage = reason;
    });
    _startStream();
  }

  void _logError(String source, String message) {
    debugPrint('[RoverStream][$source][ERROR] $message');
  }

  void _disableMlForSession(String source, String message) {
    _logError(source, message);
    _detectionService.dispose();
    _mlUnavailable = true;
    if (mounted) {
      setState(() {
        _detections = const [];
        _detectionError = '$message\nML is disabled until app restart.';
      });
    }
    widget.onMlUnavailable?.call(message);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.videocam_off,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 8),
              Text(
                'Stream unavailable',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (_streamEndpoint != null) ...[
                const SizedBox(height: 6),
                Text(
                  _streamEndpoint!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_errorMessage != null) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(onPressed: _startStream, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_currentFrame == null) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: Container(
          color: Theme.of(context).colorScheme.surface,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final image = Image.memory(
      _currentFrame!,
      gaplessPlayback: true,
      fit: BoxFit.fill,
    );

    final transformedVisualLayer = LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            image,
            ..._detections.map((detection) {
              final rect = detection.normalizedRect;
              return Positioned(
                left: rect.left * constraints.maxWidth,
                top: rect.top * constraints.maxHeight,
                width: rect.width * constraints.maxWidth,
                height: rect.height * constraints.maxHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.lightGreenAccent,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.topLeft,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: _buildReadableOverlayText(
                      child: Text(
                        '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );

    Widget orientedImage;
    switch (widget.orientationMode) {
      case StreamOrientationMode.normal:
        orientedImage = Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: RotatedBox(quarterTurns: 2, child: transformedVisualLayer),
        );
      case StreamOrientationMode.rotate180:
        orientedImage = Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: transformedVisualLayer,
        );
      case StreamOrientationMode.rotate180Mirrored:
        orientedImage = transformedVisualLayer;
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Stack(
        fit: StackFit.expand,
        children: [
          orientedImage,
          if (widget.detectionMode != ObjectDetectionMode.off &&
              widget.showDiagnostics)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ML ${_lastInferenceMs}ms avg:${_averageInferenceMs().toStringAsFixed(0)} | obj:${_detections.length} P:${_processedInferenceCount} S:${_skippedInferenceCount} R:${_reconnectCount}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          if (_detectionError != null)
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.all(6),
                color: Colors.red.withAlpha(180),
                child: Text(
                  _detectionError!,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReadableOverlayText({required Widget child}) {
    switch (widget.orientationMode) {
      case StreamOrientationMode.normal:
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: RotatedBox(quarterTurns: 2, child: child),
        );
      case StreamOrientationMode.rotate180:
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: child,
        );
      case StreamOrientationMode.rotate180Mirrored:
        return child;
    }
  }

  String _normalizeLabel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('person') || lower.contains('human')) {
      return 'Person';
    }
    if (lower.contains('car') ||
        lower.contains('vehicle') ||
        lower.contains('truck') ||
        lower.contains('bus') ||
        lower.contains('motorcycle') ||
        lower.contains('bike')) {
      return 'Vehicle';
    }
    if (raw.isEmpty) {
      return 'Object';
    }
    return raw;
  }

  double _averageInferenceMs() {
    if (_processedInferenceCount == 0) {
      return 0;
    }
    return _totalInferenceMs / _processedInferenceCount;
  }
}
