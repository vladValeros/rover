import 'dart:io';
import 'dart:typed_data';

/// Stores motion-triggered snapshots into a local temp directory.
class MotionSnapshotStorageService {
  Future<String> save(Uint8List jpegBytes) async {
    final dir = Directory(
      '${Directory.systemTemp.path}/rover_motion_snapshots',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final now = DateTime.now();
    final fileName =
        'motion_${now.year.toString().padLeft(4, '0')}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}_'
        '${now.millisecond.toString().padLeft(3, '0')}.jpg';

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(jpegBytes, flush: true);
    return file.path;
  }
}
