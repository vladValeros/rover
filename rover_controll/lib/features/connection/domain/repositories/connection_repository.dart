import '../../../../core/error/failures.dart';
import '../entities/connection_entity.dart';

abstract interface class ConnectionRepository {
  Future<(ConnectionEntity?, AppFailure?)> loadSavedConnection();
  Future<AppFailure?> saveConnection(ConnectionEntity connection);
  Future<AppFailure?> testConnection(String ipAddress);
  Future<(String?, AppFailure?)> discoverRoverIp();
}
