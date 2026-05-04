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
        ),
      );
      return null;
    } on DioException catch (e) {
      return ConnectionFailure('Could not reach rover: ${e.message}');
    } catch (e) {
      return ConnectionFailure('Unexpected error: $e');
    }
  }
}
