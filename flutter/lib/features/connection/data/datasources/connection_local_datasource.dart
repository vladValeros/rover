import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';

@lazySingleton
class ConnectionLocalDatasource {
  Future<String?> loadRoverIpAddress() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(AppConstants.savedRoverIpKey);
    } catch (_) {
      return null;
    }
  }

  Future<AppFailure?> saveRoverIpAddress(String ipAddress) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.savedRoverIpKey, ipAddress);
      return null;
    } catch (e) {
      return StorageFailure('Failed to save address: $e');
    }
  }
}
