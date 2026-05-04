import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../constants/app_constants.dart';

@lazySingleton
class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: AppConstants.httpConnectionTimeout,
        receiveTimeout: AppConstants.httpCommandTimeout,
      ),
    );
  }

  Dio get dio => _dio;

  void updateBaseUrl(String ip) {
    _dio.options.baseUrl = 'http://$ip:${AppConstants.controlPort}';
  }
}
