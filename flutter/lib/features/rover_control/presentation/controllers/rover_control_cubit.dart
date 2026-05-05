import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
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
  static const Duration _ledKeepAliveInterval = Duration(seconds: 8);
  Timer? _ledKeepAliveTimer;
  bool _ledRequestInFlight = false;

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
      _startLedKeepAlive();
    } else if (command == RoverCommand.ledOff) {
      _desiredLedOn = false;
      _stopLedKeepAlive();
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

    final failure = await _sendLedOnSilently(reason: 'reconnect');
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

  AppFailure? _onLedKeepAliveSkip() {
    developer.log(
      'LED keep-alive skipped because another LED request is in flight',
      name: 'RoverControlCubit',
    );
    return null;
  }

  void _startLedKeepAlive() {
    _ledKeepAliveTimer?.cancel();
    developer.log(
      'LED keep-alive started (${_ledKeepAliveInterval.inSeconds}s)',
      name: 'RoverControlCubit',
    );
    _ledKeepAliveTimer = Timer.periodic(_ledKeepAliveInterval, (_) async {
      if (!_desiredLedOn) return;
      final failure = await _sendLedOnSilently(reason: 'keep-alive');
      if (failure != null) {
        developer.log(
          'LED keep-alive failed: ${failure.message}',
          name: 'RoverControlCubit',
        );
      }
    });
  }

  void _stopLedKeepAlive() {
    if (_ledKeepAliveTimer == null) return;
    _ledKeepAliveTimer?.cancel();
    _ledKeepAliveTimer = null;
    developer.log('LED keep-alive stopped', name: 'RoverControlCubit');
  }

  Future<AppFailure?> _sendLedOnSilently({required String reason}) async {
    if (_ledRequestInFlight) return _onLedKeepAliveSkip();
    _ledRequestInFlight = true;
    developer.log('Sending silent LED ON ($reason)', name: 'RoverControlCubit');
    try {
      return await _sendRoverCommandUseCase.execute(RoverCommand.ledOn);
    } finally {
      _ledRequestInFlight = false;
    }
  }

  @override
  Future<void> close() {
    _stopLedKeepAlive();
    return super.close();
  }
}
