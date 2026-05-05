import 'package:go_router/go_router.dart';

import 'presentation/screens/connection_screen.dart';

abstract final class ConnectionRoutes {
  static const String path = '/';

  static List<GoRoute> get routes => [
    GoRoute(path: path, builder: (context, state) => const ConnectionScreen()),
  ];
}
