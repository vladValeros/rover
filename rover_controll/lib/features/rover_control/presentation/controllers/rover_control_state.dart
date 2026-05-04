import 'package:freezed_annotation/freezed_annotation.dart';

part 'rover_control_state.freezed.dart';

@freezed
abstract class RoverControlState with _$RoverControlState {
  const factory RoverControlState.idle() = _Idle;
  const factory RoverControlState.commanding() = _Commanding;
  const factory RoverControlState.failure(String message) = _Failure;
}
