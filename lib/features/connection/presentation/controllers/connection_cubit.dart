import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/connection_entity.dart';
import '../../domain/usecases/load_saved_connection_usecase.dart';
import '../../domain/usecases/save_connection_usecase.dart';
import '../../domain/usecases/test_connection_usecase.dart';
import 'connection_state.dart';

@injectable
class ConnectionCubit extends Cubit<RoverConnectionState> {
  ConnectionCubit(
    this._loadSavedConnectionUseCase,
    this._saveConnectionUseCase,
    this._testConnectionUseCase,
  ) : super(const RoverConnectionState.initial());

  final LoadSavedConnectionUseCase _loadSavedConnectionUseCase;
  final SaveConnectionUseCase _saveConnectionUseCase;
  final TestConnectionUseCase _testConnectionUseCase;

  Future<void> loadSavedAddress() async {
    emit(const RoverConnectionState.loading());
    final (entity, failure) = await _loadSavedConnectionUseCase.execute();
    if (failure != null) {
      emit(RoverConnectionState.failure(failure.message));
      return;
    }
    if (entity != null) {
      emit(RoverConnectionState.loaded(entity));
    } else {
      emit(const RoverConnectionState.initial());
    }
  }

  Future<void> testConnection(String ipAddress) async {
    emit(const RoverConnectionState.testing());
    final failure = await _testConnectionUseCase.execute(ipAddress);
    if (failure != null) {
      emit(RoverConnectionState.failure(failure.message));
    } else {
      emit(const RoverConnectionState.testSuccess());
    }
  }

  Future<void> saveConnection(String ipAddress) async {
    final connection = ConnectionEntity(roverIpAddress: ipAddress);
    final failure = await _saveConnectionUseCase.execute(connection);
    if (failure != null) {
      emit(RoverConnectionState.failure(failure.message));
    } else {
      emit(RoverConnectionState.saved(connection));
    }
  }
}
