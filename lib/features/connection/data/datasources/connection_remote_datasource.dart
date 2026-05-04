import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';

@lazySingleton
class ConnectionRemoteDatasource {
  const ConnectionRemoteDatasource(this._dioClient);

  final DioClient _dioClient;

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
}
