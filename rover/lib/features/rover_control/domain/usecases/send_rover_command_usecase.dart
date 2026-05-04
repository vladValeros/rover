import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/rover_command.dart';
import '../repositories/rover_control_repository.dart';

@lazySingleton
class SendRoverCommandUseCase {
  const SendRoverCommandUseCase(this._repository);

  final RoverControlRepository _repository;

  Future<AppFailure?> execute(RoverCommand command) =>
      _repository.sendCommand(command);
}
