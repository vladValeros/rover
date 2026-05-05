import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/entities/connection_entity.dart';

part 'connection_state.freezed.dart';

@freezed
abstract class RoverConnectionState with _$RoverConnectionState {
  const factory RoverConnectionState.initial() = _Initial;
  const factory RoverConnectionState.loading() = _Loading;
  const factory RoverConnectionState.loaded(ConnectionEntity connection) =
      _Loaded;
  const factory RoverConnectionState.testing() = _Testing;
  const factory RoverConnectionState.testSuccess() = _TestSuccess;
  const factory RoverConnectionState.discovering() = _Discovering;
  const factory RoverConnectionState.discovered(String ipAddress) = _Discovered;
  const factory RoverConnectionState.saved(ConnectionEntity connection) =
      _Saved;
  const factory RoverConnectionState.failure(String message) = _Failure;
}
