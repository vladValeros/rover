import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

/// Runs MiDaS Small TFLite to estimate monocular depth from a JPEG frame.
///
/// MiDaS convention: **higher output value = closer to the camera** (inverse
/// depth).  The service returns the mean inverse-depth of the **center third**
/// of the frame, normalised to [0, 1].  A value above [blockThreshold] means
/// the path ahead is likely obstructed.
///
/// The model must be placed at `assets/ml/midas_small.tflite`.
/// If the file is missing the service marks itself unavailable and all calls
/// return `null` — the autopilot treats this as "path clear" so the rover
/// does not get stuck indefinitely.
class DepthEstimationService {
  static const String _modelAsset = 'assets/ml/midas_small.tflite';
  static const int _inputSize = 256;

  Interpreter? _interpreter;
  bool _unavailable = false;
  String? _lastError;

  /// True when the TFLite model could not be loaded.
  bool get isUnavailable => _unavailable;

  /// The last model-load or inference error observed by this service.
  String? get lastError => _lastError;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns the mean inverse-depth of the centre third of [jpegBytes],
  /// normalised to [0, 1].  Returns `null` on any error.
  Future<double?> computeCenterDepth(Uint8List jpegBytes) async {
    if (_unavailable) {
      _lastError ??= 'Depth model unavailable.';
      return null;
    }

    try {
      final interpreter = await _ensureInterpreter();
      if (interpreter == null) return null;

      // Decode & resize.
      final decoded = img.decodeJpg(jpegBytes);
      if (decoded == null) return null;
      final resized = img.copyResize(
        decoded,
        width: _inputSize,
        height: _inputSize,
        interpolation: img.Interpolation.linear,
      );

      // Build input tensor [1, 256, 256, 3] — RGB normalised [0, 1].
      final input = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (y) => List.generate(_inputSize, (x) {
            final p = resized.getPixel(x, y);
            return [p.r / 255.0, p.g / 255.0, p.b / 255.0];
          }),
        ),
      );

      // Output buffer [1, 256, 256, 1].
      final output = List.generate(
        1,
        (_) => List.generate(
          _inputSize,
          (_) => List.generate(_inputSize, (_) => List.filled(1, 0.0)),
        ),
      );

      interpreter.run(input, output);
      _lastError = null;

      return _centerMean(_flattenDepthMap(output[0]));
    } catch (e) {
      _lastError = e.toString();
      debugPrint('[DepthEstimationService][inference][ERROR] $_lastError');
      return null;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<Interpreter?> _ensureInterpreter() async {
    if (_interpreter != null) return _interpreter;
    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      _lastError = null;
      return _interpreter;
    } catch (e) {
      _unavailable = true;
      _lastError = 'Failed to load depth model: $e';
      debugPrint('[DepthEstimationService][load][ERROR] $_lastError');
      return null;
    }
  }

  /// Mean value of the centre 1/3 columns × centre 1/3 rows.
  double _centerMean(List<List<double>> depthMap) {
    final h = depthMap.length;
    final w = depthMap[0].length;
    final rowStart = h ~/ 3;
    final rowEnd = h * 2 ~/ 3;
    final colStart = w ~/ 3;
    final colEnd = w * 2 ~/ 3;

    double sum = 0;
    int count = 0;
    for (int r = rowStart; r < rowEnd; r++) {
      for (int c = colStart; c < colEnd; c++) {
        sum += depthMap[r][c];
        count++;
      }
    }
    if (count == 0) return 0;

    final raw = sum / count;

    // Normalise the raw MiDaS output to [0, 1] using a simple running-min/max
    // that resets per call — adequate for relative decisions.
    double min = double.infinity;
    double max = double.negativeInfinity;
    for (final row in depthMap) {
      for (final v in row) {
        if (v < min) min = v;
        if (v > max) max = v;
      }
    }
    final range = max - min;
    if (range == 0) return 0;
    return (raw - min) / range;
  }

  List<List<double>> _flattenDepthMap(List<List<List<double>>> depthMap) {
    return depthMap
        .map((row) => row.map((pixel) => pixel.first).toList())
        .toList();
  }
}
