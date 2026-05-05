import 'dart:io';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';

@lazySingleton
class ConnectionRemoteDatasource {
  const ConnectionRemoteDatasource(this._dioClient);

  final DioClient _dioClient;

  static const int _scanStartHost = 2;
  static const int _scanEndHost = 254;
  static const int _scanBatchSize = 24;

  Future<AppFailure?> pingRover(String ipAddress) async {
    try {
      final Dio dio = _dioClient.dio;
      await dio.get(
        'http://$ipAddress:${AppConstants.controlPort}/',
        options: Options(
          receiveTimeout: AppConstants.httpConnectionTimeout,
          sendTimeout: AppConstants.httpConnectionTimeout,
          // The rover's root path may return a non-2xx status — treat any
          // response as "reachable".
          validateStatus: (_) => true,
        ),
      );
      return null;
    } on DioException catch (e) {
      return ConnectionFailure(_friendlyDioError(e, ipAddress));
    } catch (e) {
      return ConnectionFailure('Unexpected error: $e');
    }
  }

  Future<(String?, AppFailure?)> discoverRoverIp() async {
    try {
      final wifiIp = await _getLocalPrivateIpv4();
      if (wifiIp == null || wifiIp.isEmpty) {
        return (
          null,
          ConnectionFailure(
            'Could not read local network IP. Connect to rover network first.',
          ),
        );
      }

      final parts = wifiIp.split('.');
      if (parts.length != 4) {
        return (null, ConnectionFailure('Unexpected WiFi IP format: $wifiIp'));
      }

      final subnetPrefix = '${parts[0]}.${parts[1]}.${parts[2]}';
      final selfHost = int.tryParse(parts[3]);

      final scanDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(milliseconds: 450),
          sendTimeout: const Duration(milliseconds: 450),
          receiveTimeout: const Duration(milliseconds: 450),
          validateStatus: (_) => true,
          responseType: ResponseType.plain,
        ),
      );

      for (
        int batchStart = _scanStartHost;
        batchStart <= _scanEndHost;
        batchStart += _scanBatchSize
      ) {
        final batchEnd = (batchStart + _scanBatchSize - 1) > _scanEndHost
            ? _scanEndHost
            : (batchStart + _scanBatchSize - 1);

        final candidates = <Future<String?>>[];
        for (int host = batchStart; host <= batchEnd; host++) {
          if (host == selfHost) {
            continue;
          }
          final candidateIp = '$subnetPrefix.$host';
          candidates.add(_probeRover(scanDio, candidateIp));
        }

        final results = await Future.wait(candidates);
        for (final ip in results) {
          if (ip != null) {
            return (ip, null);
          }
        }
      }

      return (
        null,
        ConnectionFailure(
          'Rover was not found on this WiFi subnet.\n'
          'Make sure rover and phone are on the same hotspot/network.',
        ),
      );
    } catch (e) {
      return (null, ConnectionFailure('Auto-detect failed: $e'));
    }
  }

  String _friendlyDioError(DioException e, String ipAddress) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Timed out connecting to $ipAddress.\n'
            'Is the rover powered on and on the same WiFi?';
      case DioExceptionType.connectionError:
        return 'Cannot reach $ipAddress.\n'
            'Make sure your phone is connected to the rover\'s WiFi network.';
      default:
        return 'Connection failed (${e.type.name}).\n'
            'Check the IP address and try again.';
    }
  }

  Future<String?> _probeRover(Dio dio, String ipAddress) async {
    try {
      final response = await dio.get<String>(
        'http://$ipAddress:${AppConstants.controlPort}/',
      );
      // Accept any HTTP response on the control port — the web UI content
      // changes between firmware versions so we only check reachability.
      if (response.statusCode != null) {
        return ipAddress;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _getLocalPrivateIpv4() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        final ip = address.address;
        if (_isPrivateIpv4(ip)) {
          return ip;
        }
      }
    }
    return null;
  }

  bool _isPrivateIpv4(String ip) {
    return ip.startsWith('10.') ||
        ip.startsWith('192.168.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(ip);
  }
}
