import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../entities/connection_entity.dart';
import '../repositories/connection_repository.dart';

@lazySingleton
class SaveConnectionUseCase {
  const SaveConnectionUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<AppFailure?> execute(ConnectionEntity connection) =>
      _repository.saveConnection(connection);
}
