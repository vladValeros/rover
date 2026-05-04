abstract final class AppFailure {
  final String message;
  const AppFailure(this.message);
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
}

final class ConnectionFailure extends AppFailure {
  const ConnectionFailure(super.message);
}

final class StorageFailure extends AppFailure {
  const StorageFailure(super.message);
}
