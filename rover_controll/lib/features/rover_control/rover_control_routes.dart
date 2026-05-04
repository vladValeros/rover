import 'package:go_router/go_router.dart';

import 'presentation/screens/rover_control_screen.dart';

abstract final class RoverControlRoutes {
  static const String path = '/rover';

  static List<GoRoute> get routes => [
    GoRoute(
      path: path,
      builder: (context, state) => const RoverControlScreen(),
    ),
  ];
}
