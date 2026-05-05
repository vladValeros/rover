import '../../../../core/error/failures.dart';
import '../entities/rover_command.dart';

abstract interface class RoverControlRepository {
  Future<AppFailure?> sendCommand(RoverCommand command);
}
