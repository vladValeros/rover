import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../repositories/connection_repository.dart';

@lazySingleton
class DiscoverRoverIpUseCase {
  const DiscoverRoverIpUseCase(this._repository);

  final ConnectionRepository _repository;

  Future<(String?, AppFailure?)> execute() => _repository.discoverRoverIp();
}
