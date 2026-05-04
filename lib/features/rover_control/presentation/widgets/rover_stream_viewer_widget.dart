import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;
import 'package:image/image.dart' as img;

import '../../../../app/locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';

enum StreamOrientationMode { normal, rotate180, rotate180Mirrored }

enum ObjectDetectionMode { off, general, personOnly, vehicleOnly }

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
    super.key,
  });

  final StreamOrientationMode orientationMode;
  final ObjectDetectionMode detectionMode;
  final int refreshNonce;

  @override
  State<RoverStreamViewerWidget> createState() =>
      _RoverStreamViewerWidgetState();
}

class _RoverStreamViewerWidgetState extends State<RoverStreamViewerWidget> {
  static const Duration _watchdogInterval = Duration(seconds: 2);
  static const Duration _freezeThreshold = Duration(seconds: 6);
  static const Duration _autoReconnectDelay = Duration(seconds: 1);
  static const Duration _inferenceInterval = Duration(milliseconds: 800);

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
  mlkit.ObjectDetector? _objectDetector;
  bool _mlUnavailable = false;

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
    _objectDetector?.close();
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

      final response = await dio.getUri<ResponseBody>(
        streamUri,
        options: Options(
          responseType: ResponseType.stream,
          // Keep stream open for a long-lived MJPEG connection.
          receiveTimeout: const Duration(minutes: 5),
          headers: const {'Accept': 'multipart/x-mixed-replace'},
        ),
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
    if (lastInferenceAt != null &&
        now.difference(lastInferenceAt) < _inferenceInterval) {
      return;
    }

    _isDetecting = true;
    _lastInferenceAt = now;

    final watch = Stopwatch()..start();
    try {
      final detector = await _ensureDetector();
      if (detector == null) {
        return;
      }

      final file = File('${Directory.systemTemp.path}/rover_frame_ml.jpg');
      await file.writeAsBytes(frame, flush: true);

      final decoded = img.decodeJpg(frame);
      if (decoded == null) {
        return;
      }

      final inputImage = mlkit.InputImage.fromFilePath(file.path);
      final objects = await detector.processImage(inputImage);

      final mapped = <DetectionOverlayBox>[];
      for (final object in objects) {
        final label = object.labels.isNotEmpty
            ? object.labels.first.text
            : 'Object';
        final confidence = object.labels.isNotEmpty
            ? object.labels.first.confidence
            : 0;

        if (!_shouldIncludeLabel(label)) {
          continue;
        }

        final rect = object.boundingBox;
        final normalizedLeft = (rect.left / decoded.width).clamp(0.0, 1.0);
        final normalizedTop = (rect.top / decoded.height).clamp(0.0, 1.0);
        final normalizedWidth = (rect.width / decoded.width).clamp(0.0, 1.0);
        final normalizedHeight = (rect.height / decoded.height).clamp(0.0, 1.0);
        if (normalizedWidth <= 0 || normalizedHeight <= 0) {
          continue;
        }

        mapped.add(
          DetectionOverlayBox(
            normalizedRect: Rect.fromLTWH(
              normalizedLeft,
              normalizedTop,
              normalizedWidth,
              normalizedHeight,
            ),
            label: label,
            confidence: confidence.toDouble(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _detections = mapped;
          _detectionError = null;
        });
      }
    } on MissingPluginException {
      const message =
          'ML plugin not available in current runtime. '
          'Stop app and run full rebuild (flutter clean; flutter run).';
      _disableMlForSession('detector', message);
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
        });
      }
      _isDetecting = false;
    }
  }

  Future<mlkit.ObjectDetector?> _ensureDetector() async {
    if (_mlUnavailable) {
      return null;
    }

    if (_objectDetector != null) {
      return _objectDetector;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      const message =
          'Object detection is only supported on Android/iOS for this build.';
      _logError('detector-init', message);
      if (mounted) {
        setState(() {
          _detectionError = message;
        });
      }
      return null;
    }

    try {
      final options = mlkit.ObjectDetectorOptions(
        mode: mlkit.DetectionMode.single,
        classifyObjects: true,
        multipleObjects: true,
      );
      _objectDetector = mlkit.ObjectDetector(options: options);
      return _objectDetector;
    } on MissingPluginException {
      const message =
          'ML plugin not available in current app runtime. '
          'Stop the app and run a full rebuild (not hot reload).';
      _disableMlForSession('detector-init', message);
      return null;
    } catch (e) {
      _logError('detector-init', e.toString());
      if (mounted) {
        setState(() {
          _detectionError = 'Detector unavailable: $e';
        });
      }
      return null;
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
    _objectDetector?.close();
    _objectDetector = null;
    _mlUnavailable = true;
    if (mounted) {
      setState(() {
        _detections = const [];
        _detectionError = '$message\nML is disabled until app restart.';
      });
    }
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
                    child: Text(
                      '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
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
          if (widget.detectionMode != ObjectDetectionMode.off)
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
                  'ML ${_lastInferenceMs}ms | ${_detections.length} obj',
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
}
