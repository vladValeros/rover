import 'dart:io';

import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as mlkit;

/// Raw detector result used by stream overlay mapping.
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

/// MLKit object detection service isolated in ml_object_detection feature.
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

    // Parse JPEG dimensions from the frame header — avoids a full CPU decode.
    final size = _jpegDimensions(frame);
    if (size == null) {
      return const [];
    }

    // Write without flush — avoids a kernel-level disk sync on every frame.
    final file = File('${Directory.systemTemp.path}/rover_frame_ml.jpg');
    await file.writeAsBytes(frame);

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
      final normalizedLeft = (box.left / size.width).clamp(0.0, 1.0);
      final normalizedTop = (box.top / size.height).clamp(0.0, 1.0);
      final normalizedWidth = (box.width / size.width).clamp(0.0, 1.0);
      final normalizedHeight = (box.height / size.height).clamp(0.0, 1.0);
      if (normalizedWidth <= 0 || normalizedHeight <= 0) {
        continue;
      }

      mapped.add(
        RawDetection(
          normalizedRect: Rect.fromLTWH(
            normalizedLeft.toDouble(),
            normalizedTop.toDouble(),
            normalizedWidth.toDouble(),
            normalizedHeight.toDouble(),
          ),
          label: label,
          confidence: confidence,
        ),
      );
    }

    return mapped;
  }

  /// Parses JPEG width and height from the raw byte header without doing a
  /// full image decode. Scans for SOF markers (0xFFC0, 0xFFC2) which carry
  /// the frame dimensions.
  ({int width, int height})? _jpegDimensions(Uint8List bytes) {
    int i = 0;
    while (i < bytes.length - 1) {
      if (bytes[i] != 0xFF) {
        i++;
        continue;
      }
      final marker = bytes[i + 1];
      // SOF0 = 0xC0, SOF1 = 0xC1, SOF2 = 0xC2 — all carry dimensions at the
      // same offset within the segment.
      if (marker == 0xC0 || marker == 0xC1 || marker == 0xC2) {
        if (i + 8 >= bytes.length) break;
        final height = (bytes[i + 5] << 8) | bytes[i + 6];
        final width = (bytes[i + 7] << 8) | bytes[i + 8];
        if (width > 0 && height > 0) return (width: width, height: height);
      }
      // Skip over segment: length field is 2 bytes at offset +2 from marker.
      if (i + 3 < bytes.length && marker != 0xD8 && marker != 0xD9) {
        final segLen = (bytes[i + 2] << 8) | bytes[i + 3];
        i += 2 + segLen;
      } else {
        i += 2;
      }
    }
    return null;
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
