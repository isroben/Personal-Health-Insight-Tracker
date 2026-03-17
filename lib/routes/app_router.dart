/// ==========================================================================
/// app_router.dart — Named Route Definitions
/// ==========================================================================
/// Centralized routing configuration for the app.
/// Usage: Navigator.pushNamed(context, AppRouter.logRoute);
/// ==========================================================================

import 'package:flutter/material.dart';

import '../app.dart';
import '../screens/home_screen.dart';
import '../screens/logging_screen.dart';
import '../screens/insights_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';

class AppRouter {
  static const String shellRoute = '/'; // Bottom nav shell
  static const String homeRoute = '/home';
  static const String logRoute = '/log';
  static const String insightsRoute = '/insights';
  static const String reportsRoute = '/reports';
  static const String settingsRoute = '/settings';
  static const String authRoute = '/auth'; // TODO: Implement Auth wrapper

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case shellRoute:
        return MaterialPageRoute(builder: (_) => const MainShell());
      case homeRoute:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case logRoute:
        return MaterialPageRoute(
          builder: (_) => const LoggingScreen(),
          fullscreenDialog: true, // Slides up from bottom
        );
      case insightsRoute:
        return MaterialPageRoute(builder: (_) => const InsightsScreen());
      case reportsRoute:
        return MaterialPageRoute(builder: (_) => const ReportsScreen());
      case settingsRoute:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}
