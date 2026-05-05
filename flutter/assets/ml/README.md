# ML Model Assets

Place `midas_small.tflite` here before running with autopilot enabled.

## How to get the model

Download MiDaS v2.1 Small (TFLite) from:
https://github.com/isl-org/MiDaS/releases

Rename the file to `midas_small.tflite` and place it in this directory.

- Input:  [1, 256, 256, 3]  float32  (RGB normalized to [0, 1])
- Output: [1, 256, 256]     float32  (inverse depth — higher = closer)
