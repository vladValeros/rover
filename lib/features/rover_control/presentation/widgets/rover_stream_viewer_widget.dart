import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../app/locator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';

class RoverStreamViewerWidget extends StatefulWidget {
  const RoverStreamViewerWidget({super.key});

  @override
  State<RoverStreamViewerWidget> createState() =>
      _RoverStreamViewerWidgetState();
}

class _RoverStreamViewerWidgetState extends State<RoverStreamViewerWidget> {
  Uint8List? _currentFrame;
  StreamSubscription<Uint8List>? _streamSubscription;
  bool _hasError = false;
  String? _errorMessage;
  String? _streamEndpoint;
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _startStream();
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    _streamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startStream() async {
    _cancelToken?.cancel();
    await _streamSubscription?.cancel();

    setState(() {
      _hasError = false;
      _currentFrame = null;
      _errorMessage = null;
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
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.toString();
                });
              }
            },
          );
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.message ?? e.type.name;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
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
          setState(() => _currentFrame = frame);
        }
        return;
      }
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

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(math.pi),
        child: RotatedBox(
          quarterTurns: 2,
          child: Image.memory(
            _currentFrame!,
            gaplessPlayback: true,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
