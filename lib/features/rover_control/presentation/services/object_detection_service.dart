import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;
import 'package:image/image.dart' as img;

class RawDetection {
  const RawDetection({
    required this.normalizedRect,
    required this.label,
    required this.confidence,
  });

  final Rect normalizedRect;
  final String label;
  final double confidence;
}

class ObjectDetectionService {
  mlkit.ObjectDetector? _detector;
  bool _unavailable = false;

  bool get isUnavailable => _unavailable;

  Future<List<RawDetection>> detect(
    Uint8List frame, {
    required double confidenceThreshold,
  }) async {
    final detector = await _ensureDetector();
    if (detector == null) {
      return const [];
    }

    final file = File('${Directory.systemTemp.path}/rover_frame_ml.jpg');
    await file.writeAsBytes(frame, flush: true);

    final decoded = img.decodeJpg(frame);
    if (decoded == null) {
      return const [];
    }

    final inputImage = mlkit.InputImage.fromFilePath(file.path);
    final objects = await detector.processImage(inputImage);

    final mapped = <RawDetection>[];
    for (final object in objects) {
      final label = object.labels.isNotEmpty
          ? object.labels.first.text
          : 'Object';
      final double confidence = object.labels.isNotEmpty
          ? object.labels.first.confidence.toDouble()
          : 0.0;
      if (confidence < confidenceThreshold) {
        continue;
      }

      final box = object.boundingBox;
      final normalizedLeft = (box.left / decoded.width)
          .clamp(0.0, 1.0)
          .toDouble();
      final normalizedTop = (box.top / decoded.height)
          .clamp(0.0, 1.0)
          .toDouble();
      final normalizedWidth = (box.width / decoded.width)
          .clamp(0.0, 1.0)
          .toDouble();
      final normalizedHeight = (box.height / decoded.height)
          .clamp(0.0, 1.0)
          .toDouble();
      if (normalizedWidth <= 0 || normalizedHeight <= 0) {
        continue;
      }

      mapped.add(
        RawDetection(
          normalizedRect: Rect.fromLTWH(
            normalizedLeft,
            normalizedTop,
            normalizedWidth,
            normalizedHeight,
          ),
          label: label,
          confidence: confidence,
        ),
      );
    }

    return mapped;
  }

  Future<mlkit.ObjectDetector?> _ensureDetector() async {
    if (_unavailable) {
      return null;
    }
    if (_detector != null) {
      return _detector;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      _unavailable = true;
      return null;
    }

    try {
      _detector = mlkit.ObjectDetector(
        options: mlkit.ObjectDetectorOptions(
          mode: mlkit.DetectionMode.single,
          classifyObjects: true,
          multipleObjects: true,
        ),
      );
      return _detector;
    } on MissingPluginException {
      _unavailable = true;
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
  }
}
