import 'package:flutter/material.dart';

import '../widgets/root_shell.dart';
import 'app_routes.dart';

abstract final class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.root:
      default:
        return MaterialPageRoute(
          builder: (_) => const RootShell(),
          settings: settings,
        );
    }
  }
}
