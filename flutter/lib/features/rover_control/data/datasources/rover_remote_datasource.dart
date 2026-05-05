import 'dart:developer' as developer;

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
    final watch = Stopwatch()..start();
    final requestPath = command.path;
    final baseUrl = _dioClient.dio.options.baseUrl;
    developer.log(
      'Sending rover command: ${command.name} -> $baseUrl$requestPath',
      name: 'RoverCommand',
    );

    try {
      await _dioClient.dio.get(command.path);
      developer.log(
        'Command success: ${command.name} in ${watch.elapsedMilliseconds}ms',
        name: 'RoverCommand',
      );
      return null;
    } on DioException catch (e) {
      developer.log(
        'Command DioException: ${command.name} '
        'type=${e.type.name} '
        'status=${e.response?.statusCode} '
        'elapsed=${watch.elapsedMilliseconds}ms '
        'message=${e.message}',
        name: 'RoverCommand',
        error: e,
        stackTrace: e.stackTrace,
      );
      return NetworkFailure(
        _friendlyDioError(e, command, watch.elapsedMilliseconds),
      );
    } catch (e, st) {
      developer.log(
        'Command unexpected error: ${command.name} '
        'elapsed=${watch.elapsedMilliseconds}ms '
        'error=$e',
        name: 'RoverCommand',
        error: e,
        stackTrace: st,
      );
      return NetworkFailure('Unexpected error: $e');
    }
  }

  String _friendlyDioError(
    DioException e,
    RoverCommand command,
    int elapsedMs,
  ) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Command ${command.name} timed out after ${elapsedMs}ms. '
            'Rover may be offline or not responding in time.';
      case DioExceptionType.connectionError:
        return 'Cannot reach rover for ${command.name}. Check Wi-Fi and rover power.';
      default:
        return 'Command ${command.name} failed: ${e.message ?? e.type.name}';
    }
  }
}
