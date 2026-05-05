import 'package:go_router/go_router.dart';

import 'presentation/screens/rover_control_screen.dart';

abstract final class RoverControlRoutes {
  static const String path = '/rover';
  static const String previewQueryKey = 'preview';

  static String previewPath() => '$path?$previewQueryKey=1';

  static List<GoRoute> get routes => [
    GoRoute(
      path: path,
      builder: (context, state) {
        final isPreview = state.uri.queryParameters[previewQueryKey] == '1';
        return RoverControlScreen(isPreviewMode: isPreview);
      },
    ),
  ];
}
