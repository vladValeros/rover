import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../ml_object_detection/data/services/object_detection_service.dart';
import '../../../ml_object_detection/domain/enums/object_detection_mode.dart';
import '../controllers/rover_control_cubit.dart';

export '../../../ml_object_detection/domain/enums/object_detection_mode.dart';

enum StreamOrientationMode { normal, rotate180, rotate180Mirrored }

/// Lifecycle state of the MJPEG stream connection.
enum _StreamStatus {
  /// First connect or manual refresh — no frame yet.
  connecting,

  /// Actively receiving frames — normal operation.
  streaming,

  /// Frames stopped arriving; watchdog detected a freeze.
  /// Last frame is still shown with an orange banner overlay.
  frozen,

  /// A reconnect attempt failed; retrying automatically.
  error,

  /// Too many consecutive failures — rover is likely offline.
  offline,
}

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
    this.onRoverOffline,
    this.onStreamHealthChanged,
    this.onFrameAvailable,
    super.key,
  });

  final StreamOrientationMode orientationMode;
  final ObjectDetectionMode detectionMode;
  final int refreshNonce;
  final double detectionConfidenceThreshold;
  final int detectionIntervalMs;
  final double minDetectionArea;
  final bool showDiagnostics;

  /// Called when ML is not available in the current runtime.
  final ValueChanged<String>? onMlUnavailable;

  /// Called once when consecutive reconnect failures exceed the offline
  /// threshold, meaning the rover is considered powered off or unreachable.
  /// The parent screen should surface navigation options to the user.
  final VoidCallback? onRoverOffline;

  /// Called whenever stream health changes.
  /// `true`  = stream is actively delivering frames (healthy).
  /// `false` = stream is frozen, failed, or the rover is offline.
  final ValueChanged<bool>? onStreamHealthChanged;

  /// Called for every decoded JPEG frame, before ML inference.
  /// Use this to feed raw frames to additional on-device pipelines
  /// (e.g. the autopilot depth-estimation loop).
  final ValueChanged<Uint8List>? onFrameAvailable;

  @override
  State<RoverStreamViewerWidget> createState() =>
      _RoverStreamViewerWidgetState();
}

class _RoverStreamViewerWidgetState extends State<RoverStreamViewerWidget> {
  static const Duration _watchdogInterval = Duration(seconds: 2);
  static const Duration _freezeThreshold = Duration(seconds: 10);
  static const Duration _autoReconnectDelay = Duration(seconds: 1);
  static const Duration _streamConnectTimeout = Duration(seconds: 20);

  /// Declare rover offline after this many consecutive failures.
  static const int _offlineThreshold = 5;

  Uint8List? _currentFrame;
  StreamSubscription<Uint8List>? _streamSubscription;
  _StreamStatus _streamStatus = _StreamStatus.connecting;
  String? _errorMessage;
  String? _streamEndpoint;
  CancelToken? _cancelToken;
  Timer? _watchdogTimer;
  Timer? _reconnectTimer;
  DateTime? _lastFrameAt;
  DateTime? _lastChunkAt;
  int _lastChunkBytes = 0;
  int _lastBufferBytes = 0;
  int _lastFrameBytes = 0;
  int _lastReconnectDelayMs = 0;
  String _lastStreamEvent = 'init';
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
  int _consecutiveFailures = 0;
  final ObjectDetectionService _detectionService = ObjectDetectionService();

  @override
  void initState() {
    super.initState();
    _watchdogTimer = Timer.periodic(
      _watchdogInterval,
      (_) => _checkForFreeze(),
    );
    _startStream();
  }

  @override
  void didUpdateWidget(covariant RoverStreamViewerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshNonce != oldWidget.refreshNonce) {
      _resetAndRestart();
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

  // ── Stream lifecycle ─────────────────────────────────────────────────────

  Future<void> _startStream() async {
    if (_isStarting) return;
    _isStarting = true;
    _logInfo(
      'stream',
      'start requested | status=${_streamStatusLabel(_streamStatus)} '
          'failures=$_consecutiveFailures reconnects=$_reconnectCount',
    );

    _reconnectTimer?.cancel();
    _cancelToken?.cancel();
    await _streamSubscription?.cancel();

    if (mounted && _streamStatus != _StreamStatus.frozen) {
      setState(() {
        _errorMessage = null;
        _lastFrameAt = null;
      });
    }

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
      _logInfo('stream', 'connected | endpoint=$streamUri');

      final List<int> buffer = [];
      _streamSubscription = response.data!.stream.listen(
        (chunk) {
          final now = DateTime.now();
          final previousChunkAt = _lastChunkAt;
          final gapMs = previousChunkAt == null
              ? 0
              : now.difference(previousChunkAt).inMilliseconds;
          _lastChunkAt = now;
          _lastChunkBytes = chunk.length;
          buffer.addAll(chunk);
          _lastBufferBytes = buffer.length;
          if (gapMs >= 800) {
            _logWarn(
              'stream',
              'chunk gap ${gapMs}ms | chunk=${chunk.length}B '
                  'buffer=${buffer.length}B state=${_streamStatusLabel(_streamStatus)}',
            );
          }
          _extractFrames(buffer);
        },
        onError: (error) => _onStreamFailure(error.toString()),
        onDone: () => _onStreamFailure('Stream ended unexpectedly.'),
        cancelOnError: true,
      );
    } on DioException catch (e) {
      _onStreamFailure(_friendlyDioError(e));
    } catch (e) {
      _onStreamFailure(e.toString());
    } finally {
      _isStarting = false;
    }
  }

  void _extractFrames(List<int> buffer) {
    // Drain all complete JPEG frames currently available in buffer and render
    // only the newest one. This avoids lag accumulation when multiple frames
    // arrive in a burst after chunk gaps.
    Uint8List? latestFrame;
    while (true) {
      int startIndex = -1;
      int endIndex = -1;

      for (int i = 0; i < buffer.length - 1; i++) {
        if (buffer[i] == 0xFF && buffer[i + 1] == 0xD8) {
          startIndex = i;
        }
        if (startIndex != -1 &&
            buffer[i] == 0xFF &&
            buffer[i + 1] == 0xD9 &&
            i > startIndex) {
          endIndex = i + 1;
          break;
        }
      }

      if (startIndex == -1 || endIndex == -1) {
        break;
      }

      latestFrame = Uint8List.fromList(
        buffer.sublist(startIndex, endIndex + 1),
      );
      buffer.removeRange(0, endIndex + 1);
      _lastBufferBytes = buffer.length;
      _lastFrameBytes = latestFrame.length;
    }

    if (latestFrame == null) {
      return;
    }

    final frame = latestFrame;
    final recoveredFromFailure = _streamStatus != _StreamStatus.streaming;
    final previousStatus = _streamStatus;
    if (mounted) {
      setState(() {
        _currentFrame = frame;
        _lastFrameAt = DateTime.now();
        // Successful frame: reset failure tracking.
        if (_streamStatus != _StreamStatus.streaming) {
          _streamStatus = _StreamStatus.streaming;
          _consecutiveFailures = 0;
          _errorMessage = null;
        }
      });
    }
    if (previousStatus != _StreamStatus.streaming) {
      _lastStreamEvent = 'frame recovered';
      _logInfo(
        'stream',
        'frame recovered | frame=${frame.length}B '
            'buffer=${buffer.length}B reconnects=$_reconnectCount',
      );
    }
    if (recoveredFromFailure && mounted) {
      unawaited(
        context.read<RoverControlCubit>().reapplyLedStateAfterReconnect(),
      );
      widget.onStreamHealthChanged?.call(true);
    }
    widget.onFrameAvailable?.call(frame);
    _runDetectionIfNeeded(frame);
  }

  void _onStreamFailure(String message) {
    _logError('stream', message);
    if (!mounted) return;

    _consecutiveFailures++;
    _reconnectCount++;
    _lastStreamEvent = 'stream failure';

    final isOffline = _consecutiveFailures >= _offlineThreshold;
    setState(() {
      _errorMessage = message;
      _streamStatus = isOffline ? _StreamStatus.offline : _StreamStatus.error;
    });

    if (isOffline) {
      widget.onRoverOffline?.call();
    } else {
      _scheduleReconnect();
    }
    widget.onStreamHealthChanged?.call(false);
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    // Progressive back-off capped at 5 s.
    final delay = Duration(
      milliseconds:
          _autoReconnectDelay.inMilliseconds *
          (1 + (_consecutiveFailures - 1).clamp(0, 4)),
    );
    _lastReconnectDelayMs = delay.inMilliseconds;
    _logWarn(
      'stream',
      'reconnect scheduled in ${delay.inMilliseconds}ms '
          '| failures=$_consecutiveFailures reconnects=$_reconnectCount',
    );
    _reconnectTimer = Timer(delay, () {
      if (mounted) _startStream();
    });
  }

  void _checkForFreeze() {
    if (!mounted ||
        _streamStatus == _StreamStatus.offline ||
        _streamStatus == _StreamStatus.frozen ||
        _currentFrame == null ||
        _isStarting) {
      return;
    }
    final lastFrameAt = _lastFrameAt;
    if (lastFrameAt == null) return;
    final frameAge = DateTime.now().difference(lastFrameAt);

    if (frameAge > _freezeThreshold) {
      if (mounted) {
        setState(() {
          _streamStatus = _StreamStatus.frozen;
          _errorMessage = 'Stream frozen — reconnecting...';
        });
      }
      _lastStreamEvent = 'watchdog freeze';
      _logWarn(
        'stream',
        'freeze detected | frameAge=${frameAge.inMilliseconds}ms '
            'chunkAge=${_ageMs(_lastChunkAt)}ms chunk=${_lastChunkBytes}B '
            'buffer=${_lastBufferBytes}B frame=${_lastFrameBytes}B',
      );
      widget.onStreamHealthChanged?.call(false);
      _startStream();
    }
  }

  void _resetAndRestart() {
    if (!mounted) return;
    _logInfo('stream', 'manual reset');
    setState(() {
      _consecutiveFailures = 0;
      _streamStatus = _StreamStatus.connecting;
      _errorMessage = null;
      _currentFrame = null;
    });
    _startStream();
  }

  void _manualRetry() {
    _logInfo('stream', 'manual retry');
    setState(() {
      _consecutiveFailures = 0;
      _streamStatus = _StreamStatus.connecting;
      _errorMessage = null;
    });
    _startStream();
  }

  // ── ML helpers ───────────────────────────────────────────────────────────

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
            'ML plugin not available. Run flutter clean && flutter run.';
        _disableMlForSession('detector', message);
        return;
      }

      final mapped = <DetectionOverlayBox>[];
      for (final d in rawDetections) {
        final label = _normalizeLabel(d.label);
        if (!_shouldIncludeLabel(label)) continue;
        final area = d.normalizedRect.width * d.normalizedRect.height;
        if (area < widget.minDetectionArea) continue;
        mapped.add(
          DetectionOverlayBox(
            normalizedRect: d.normalizedRect,
            label: label,
            confidence: d.confidence,
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
      if (mounted) setState(() => _detectionError = e.toString());
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

  void _disableMlForSession(String source, String message) {
    _logError(source, message);
    _detectionService.dispose();
    _mlUnavailable = true;
    if (mounted) {
      setState(() {
        _detections = const [];
        _detectionError = '$message\nML disabled until restart.';
      });
    }
    widget.onMlUnavailable?.call(message);
  }

  void _logError(String source, String message) =>
      debugPrint('[RoverStream][$source][ERROR] $message');

  void _logInfo(String source, String message) =>
      debugPrint('[RoverStream][$source][INFO] $message');

  void _logWarn(String source, String message) =>
      debugPrint('[RoverStream][$source][WARN] $message');

  int _ageMs(DateTime? at) {
    if (at == null) return -1;
    return DateTime.now().difference(at).inMilliseconds;
  }

  String _streamStatusLabel(_StreamStatus status) {
    switch (status) {
      case _StreamStatus.connecting:
        return 'connecting';
      case _StreamStatus.streaming:
        return 'streaming';
      case _StreamStatus.frozen:
        return 'frozen';
      case _StreamStatus.error:
        return 'error';
      case _StreamStatus.offline:
        return 'offline';
    }
  }

  String _friendlyDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Is the rover powered on?';
      case DioExceptionType.connectionError:
        return 'Cannot reach rover. Check Wi-Fi and rover power.';
      default:
        return e.message ?? e.type.name;
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Offline — rover is declared unreachable.
    if (_streamStatus == _StreamStatus.offline) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _OfflinePanel(endpoint: _streamEndpoint, onRetry: _manualRetry),
      );
    }

    // Auto-retrying after a failure.
    if (_streamStatus == _StreamStatus.error) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _RetryingPanel(
          errorMessage: _errorMessage,
          attempt: _consecutiveFailures,
          maxAttempts: _offlineThreshold,
          onRetryNow: _manualRetry,
        ),
      );
    }

    // Initial connect — no frame received yet.
    if (_currentFrame == null) {
      return AspectRatio(
        aspectRatio: 4 / 3,
        child: _ConnectingPanel(endpoint: _streamEndpoint),
      );
    }

    // ── Active frame rendering ───────────────────────────────────────────
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
            ..._detections.map((det) {
              final rect = det.normalizedRect;
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
                  child: ColoredBox(
                    color: Colors.black54,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: _buildReadableOverlayText(
                        child: Text(
                          '${det.label} ${(det.confidence * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
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

          // Frozen banner over the last good frame.
          if (_streamStatus == _StreamStatus.frozen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.orange.withAlpha(220),
                padding: const EdgeInsets.symmetric(
                  vertical: 7,
                  horizontal: 12,
                ),
                child: const Row(
                  children: [
                    SizedBox(
                      height: 13,
                      width: 13,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Stream frozen — reconnecting...',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),

          if (widget.showDiagnostics)
            Positioned(
              left: 8,
              top: 8,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 250),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Stream ${_streamStatusLabel(_streamStatus)} '
                  'F:${_ageMs(_lastFrameAt)}ms '
                  'C:${_ageMs(_lastChunkAt)}ms\n'
                  'chunk:${_lastChunkBytes}B '
                  'buf:${_lastBufferBytes}B '
                  'frame:${_lastFrameBytes}B\n'
                  'reconnect:${_reconnectCount} '
                  'delay:${_lastReconnectDelayMs}ms\n'
                  'event:${_lastStreamEvent}${_errorMessage == null ? '' : '\nerr:${_errorMessage!}'}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),

          // ML diagnostics HUD.
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
                  'ML ${_lastInferenceMs}ms '
                  'avg:${_averageInferenceMs().toStringAsFixed(0)} | '
                  'obj:${_detections.length} '
                  'P:$_processedInferenceCount '
                  'S:$_skippedInferenceCount '
                  'R:$_reconnectCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),

          // ML error toast.
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
    if (lower.contains('person') || lower.contains('human')) return 'Person';
    if (lower.contains('car') ||
        lower.contains('vehicle') ||
        lower.contains('truck') ||
        lower.contains('bus') ||
        lower.contains('motorcycle') ||
        lower.contains('bike')) {
      return 'Vehicle';
    }
    return raw.isEmpty ? 'Object' : raw;
  }

  double _averageInferenceMs() {
    if (_processedInferenceCount == 0) return 0;
    return _totalInferenceMs / _processedInferenceCount;
  }
}

// ── Isolated UI panels ────────────────────────────────────────────────────────

/// Shown while the initial connection is being established.
class _ConnectingPanel extends StatelessWidget {
  const _ConnectingPanel({this.endpoint});
  final String? endpoint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Connecting to rover...',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          if (endpoint != null) ...[
            const SizedBox(height: 6),
            Text(endpoint!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Shown when a reconnect attempt failed but the offline threshold has
/// not yet been reached.  Auto-retrying with progress indicator.
class _RetryingPanel extends StatelessWidget {
  const _RetryingPanel({
    required this.errorMessage,
    required this.attempt,
    required this.maxAttempts,
    required this.onRetryNow,
  });

  final String? errorMessage;
  final int attempt;
  final int maxAttempts;
  final VoidCallback onRetryNow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: cs.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 40,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.signal_wifi_statusbar_connected_no_internet_4,
                    size: 48,
                    color: cs.error,
                  ),
                  const SizedBox(height: 12),
                  Text('Connection interrupted', style: tt.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Retrying… ($attempt / $maxAttempts)',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: tt.bodySmall?.copyWith(color: cs.error),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onRetryNow,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Retry Now'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Shown when the rover is declared offline.
/// Gives the user unambiguous options: retry or go back to the menu.
/// The "Go Back" action is wired via [onRoverOffline] from the parent screen.
class _OfflinePanel extends StatelessWidget {
  const _OfflinePanel({this.endpoint, required this.onRetry});

  final String? endpoint;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return ColoredBox(
      color: cs.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.power_off_rounded,
                    size: 60,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rover is offline',
                    style: tt.titleLarge?.copyWith(color: cs.onSurface),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No response received after multiple attempts.\n'
                    'Make sure the rover is powered on and connected to this network.',
                    textAlign: TextAlign.center,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (endpoint != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        endpoint!,
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry Connection'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
