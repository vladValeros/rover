import 'package:go_router/go_router.dart';

import '../features/connection/connection_routes.dart';
import '../features/ml_settings/ml_settings_routes.dart';
import '../features/rover_control/rover_control_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: ConnectionRoutes.path,
  routes: [
    ...ConnectionRoutes.routes,
    ...RoverControlRoutes.routes,
    ...MlSettingsRoutes.routes,
  ],
);
