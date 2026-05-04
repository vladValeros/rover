import 'package:go_router/go_router.dart';

import 'presentation/screens/ml_settings_screen.dart';

abstract final class MlSettingsRoutes {
  static const String path = '/ml-settings';

  static List<GoRoute> get routes => [
    GoRoute(path: path, builder: (context, state) => const MlSettingsScreen()),
  ];
}
