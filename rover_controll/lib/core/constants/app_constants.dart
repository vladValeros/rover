abstract final class AppConstants {
  static const String defaultRoverIp = '192.168.4.1';
  static const int controlPort = 80;
  static const int streamPort = 81;

  static const String savedRoverIpKey = 'saved_rover_ip';

  static const Duration httpCommandTimeout = Duration(seconds: 3);
  static const Duration httpConnectionTimeout = Duration(seconds: 5);
}
