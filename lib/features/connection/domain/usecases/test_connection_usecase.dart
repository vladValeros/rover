import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/connection_repository.dart';

@lazySingleton
class TestConnectionUseCase {
  const TestConnectionUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<AppFailure?> execute(String ipAddress) =>
      _repository.testConnection(ipAddress);
}
