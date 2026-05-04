import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/rover_command.dart';
import '../../domain/usecases/send_rover_command_usecase.dart';
import 'rover_control_state.dart';

@injectable
class RoverControlCubit extends Cubit<RoverControlState> {
  RoverControlCubit(this._sendRoverCommandUseCase)
    : super(const RoverControlState.idle());

  final SendRoverCommandUseCase _sendRoverCommandUseCase;
  bool _desiredLedOn = false;
  DateTime? _lastLedReapplyAt;
  static const Duration _ledReapplyCooldown = Duration(seconds: 5);

  Future<void> sendCommand(RoverCommand command) async {
    developer.log(
      'UI requested command: ${command.name}',
      name: 'RoverControlCubit',
    );

    final failure = await _sendRoverCommandUseCase.execute(command);
    if (failure != null) {
      developer.log(
        'Command failed: ${command.name} -> ${failure.message}',
        name: 'RoverControlCubit',
      );
      emit(RoverControlState.failure(failure.message));
      emit(const RoverControlState.idle());
      return;
    }

    if (command == RoverCommand.ledOn) {
      _desiredLedOn = true;
    } else if (command == RoverCommand.ledOff) {
      _desiredLedOn = false;
    }

    developer.log(
      'Command completed: ${command.name} | desiredLedOn=$_desiredLedOn',
      name: 'RoverControlCubit',
    );
  }

  Future<void> reapplyLedStateAfterReconnect() async {
    if (!_desiredLedOn) {
      developer.log(
        'Reconnect detected: no LED reapply needed (desiredLedOn=false)',
        name: 'RoverControlCubit',
      );
      return;
    }

    final now = DateTime.now();
    final last = _lastLedReapplyAt;
    if (last != null && now.difference(last) < _ledReapplyCooldown) {
      developer.log(
        'Reconnect detected: LED reapply skipped (cooldown active)',
        name: 'RoverControlCubit',
      );
      return;
    }

    _lastLedReapplyAt = now;
    developer.log(
      'Reconnect detected: reapplying LED ON intent',
      name: 'RoverControlCubit',
    );

    final failure = await _sendRoverCommandUseCase.execute(RoverCommand.ledOn);
    if (failure != null) {
      developer.log(
        'LED reapply failed: ${failure.message}',
        name: 'RoverControlCubit',
      );
      return;
    }

    developer.log(
      'LED reapply succeeded after reconnect',
      name: 'RoverControlCubit',
    );
  }
}
