import 'dart:async';
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
    setState(() {
      _hasError = false;
      _currentFrame = null;
    });

    try {
      _cancelToken = CancelToken();
      final dio = locator<DioClient>().dio;
      final baseUrl = dio.options.baseUrl;
      final streamUrl = baseUrl.replaceFirst(
        ':${AppConstants.controlPort}',
        ':${AppConstants.streamPort}',
      );

      final response = await dio.get<ResponseBody>(
        '${streamUrl.isEmpty ? 'http://${AppConstants.defaultRoverIp}:${AppConstants.streamPort}' : '$streamUrl/stream'.replaceFirst('//', '/')}/stream',
        options: Options(responseType: ResponseType.stream),
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
            onError: (_) {
              if (mounted) setState(() => _hasError = true);
            },
          );
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
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
      child: Image.memory(
        _currentFrame!,
        gaplessPlayback: true,
        fit: BoxFit.cover,
      ),
    );
  }
}
