import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/connection_entity.dart';
import '../repositories/connection_repository.dart';

@lazySingleton
class LoadSavedConnectionUseCase {
  const LoadSavedConnectionUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<(ConnectionEntity?, AppFailure?)> execute() =>
      _repository.loadSavedConnection();
}
