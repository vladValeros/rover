import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app/locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';

enum StreamOrientationMode { normal, rotate180, rotate180Mirrored }

class RoverStreamViewerWidget extends StatefulWidget {
  const RoverStreamViewerWidget({
    required this.orientationMode,
    this.refreshNonce = 0,
    super.key,
  });

  final StreamOrientationMode orientationMode;
  final int refreshNonce;

  @override
  State<RoverStreamViewerWidget> createState() =>
      _RoverStreamViewerWidgetState();
}

class _RoverStreamViewerWidgetState extends State<RoverStreamViewerWidget> {
  static const Duration _watchdogInterval = Duration(seconds: 2);
  static const Duration _freezeThreshold = Duration(seconds: 6);
  static const Duration _autoReconnectDelay = Duration(seconds: 1);

  Uint8List? _currentFrame;
  StreamSubscription<Uint8List>? _streamSubscription;
  bool _hasError = false;
  String? _errorMessage;
  String? _streamEndpoint;
  CancelToken? _cancelToken;
  Timer? _watchdogTimer;
  Timer? _reconnectTimer;
  DateTime? _lastFrameAt;
  bool _isStarting = false;

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
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _streamSubscription?.cancel();
    _watchdogTimer?.cancel();
    _reconnectTimer?.cancel();
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
        return;
      }
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
      fit: BoxFit.cover,
    );

    Widget orientedImage;
    switch (widget.orientationMode) {
      case StreamOrientationMode.normal:
        orientedImage = Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: RotatedBox(quarterTurns: 2, child: image),
        );
      case StreamOrientationMode.rotate180:
        orientedImage = Transform(
          alignment: Alignment.center,
          transform: Matrix4.rotationY(math.pi),
          child: image,
        );
      case StreamOrientationMode.rotate180Mirrored:
        orientedImage = image;
    }

    return AspectRatio(aspectRatio: 4 / 3, child: orientedImage);
  }
}
