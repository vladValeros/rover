import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/rover_command.dart';
import '../../domain/repositories/rover_control_repository.dart';
import '../datasources/rover_remote_datasource.dart';

@LazySingleton(as: RoverControlRepository)
class RoverControlRepositoryImpl implements RoverControlRepository {
  const RoverControlRepositoryImpl(this._remoteDatasource);

  final RoverRemoteDatasource _remoteDatasource;

  @override
  Future<AppFailure?> sendCommand(RoverCommand command) =>
      _remoteDatasource.sendCommand(command);
}
