import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Result of a single motion analysis frame comparison.
class MotionDetectionResult {
  const MotionDetectionResult({
    required this.detected,
    required this.score,
    required this.frameWidth,
    required this.frameHeight,
  });

  /// Whether motion was detected above the configured threshold.
  final bool detected;

  /// Normalised changed-pixel ratio in [0..1].
  final double score;

  /// Width of the downscaled analysis grid.
  final int frameWidth;

  /// Height of the downscaled analysis grid.
  final int frameHeight;
}

/// Lightweight pixel-difference motion detector.
///
/// Each call to [analyse] decodes the incoming JPEG, downscales it to a small
/// analysis grid, converts to greyscale, and compares pixel-by-pixel against
/// the previous frame.  No native code or ML model is needed.
class MotionDetectionService {
  // Analysis grid dimensions (match firmware JS reference: 32×24).
  static const int _kGridW = 32;
  static const int _kGridH = 24;

  // Minimum per-pixel absolute luminance difference to count as "changed".
  static const int _kPixelDiffThreshold = 25;

  Uint8List? _prevLuma; // Flattened greyscale grid from last frame.

  /// Analyses [jpegBytes] and returns a [MotionDetectionResult].
  ///
  /// [sensitivity] uses engineering range 0.60..0.95.
  /// Higher sensitivity means lower required changed-pixel ratio.
  MotionDetectionResult analyse({
    required Uint8List jpegBytes,
    required double sensitivity,
  }) {
    final decoded = img.decodeJpg(jpegBytes);
    if (decoded == null) {
      return const MotionDetectionResult(
        detected: false,
        score: 0,
        frameWidth: _kGridW,
        frameHeight: _kGridH,
      );
    }

    final resized = img.copyResize(
      decoded,
      width: _kGridW,
      height: _kGridH,
      interpolation: img.Interpolation.average,
    );

    // Build greyscale luma buffer.
    final luma = Uint8List(_kGridW * _kGridH);
    for (int y = 0; y < _kGridH; y++) {
      for (int x = 0; x < _kGridW; x++) {
        final pixel = resized.getPixel(x, y);
        // Rec.601 luminance approximation (integer-friendly).
        final grey = ((pixel.r * 299 + pixel.g * 587 + pixel.b * 114) ~/ 1000)
            .clamp(0, 255);
        luma[y * _kGridW + x] = grey;
      }
    }

    final prev = _prevLuma;
    _prevLuma = luma;

    if (prev == null) {
      // No previous frame yet — cannot detect motion.
      return const MotionDetectionResult(
        detected: false,
        score: 0,
        frameWidth: _kGridW,
        frameHeight: _kGridH,
      );
    }

    // Count pixels whose luminance changed more than the threshold.
    int changed = 0;
    final total = _kGridW * _kGridH;
    for (int i = 0; i < total; i++) {
      if ((luma[i] - prev[i]).abs() > _kPixelDiffThreshold) {
        changed++;
      }
    }

    final score = changed / total;
    final normalizedSensitivity = sensitivity.clamp(0.60, 0.95);
    // Sensitivity maps as the minimum score fraction required.
    // Higher sensitivity → smaller threshold → easier to trigger.
    final threshold = (1.0 - normalizedSensitivity).clamp(0.05, 0.40);
    final detected = score >= threshold;

    return MotionDetectionResult(
      detected: detected,
      score: score,
      frameWidth: _kGridW,
      frameHeight: _kGridH,
    );
  }

  /// Clears the stored previous frame so the next [analyse] call starts fresh.
  void reset() => _prevLuma = null;
}
