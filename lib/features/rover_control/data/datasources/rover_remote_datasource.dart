import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/rover_command.dart';

@lazySingleton
class RoverRemoteDatasource {
  const RoverRemoteDatasource(this._dioClient);

  final DioClient _dioClient;

  Future<AppFailure?> sendCommand(RoverCommand command) async {
    try {
      await _dioClient.dio.get(command.path);
      return null;
    } on DioException catch (e) {
      return NetworkFailure('Command failed: ${e.message}');
    } catch (e) {
      return NetworkFailure('Unexpected error: $e');
    }
  }
}
