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

  Future<void> sendCommand(RoverCommand command) async {
    final failure = await _sendRoverCommandUseCase.execute(command);
    if (failure != null) {
      emit(RoverControlState.failure(failure.message));
      emit(const RoverControlState.idle());
    }
  }
}
