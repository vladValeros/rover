import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/connection_entity.dart';
import '../../domain/repositories/connection_repository.dart';
import '../datasources/connection_local_datasource.dart';
import '../datasources/connection_remote_datasource.dart';

@LazySingleton(as: ConnectionRepository)
class ConnectionRepositoryImpl implements ConnectionRepository {
  const ConnectionRepositoryImpl(this._localDatasource, this._remoteDatasource);

  final ConnectionLocalDatasource _localDatasource;
  final ConnectionRemoteDatasource _remoteDatasource;

  @override
  Future<(ConnectionEntity?, AppFailure?)> loadSavedConnection() async {
    final String? savedIp = await _localDatasource.loadRoverIpAddress();
    if (savedIp == null) return (null, null);
    return (ConnectionEntity(roverIpAddress: savedIp), null);
  }

  @override
  Future<AppFailure?> saveConnection(ConnectionEntity connection) =>
      _localDatasource.saveRoverIpAddress(connection.roverIpAddress);

  @override
  Future<AppFailure?> testConnection(String ipAddress) =>
      _remoteDatasource.pingRover(ipAddress);

  @override
  Future<(String?, AppFailure?)> discoverRoverIp() =>
      _remoteDatasource.discoverRoverIp();
}
