/// ==========================================================================
/// app.dart — Root Application Widget
/// ==========================================================================
/// Configures MaterialApp with:
/// - App-wide theme (colors, typography)
/// - Named route definitions
/// - Bottom tab navigation shell
/// ==========================================================================

import 'package:flutter/material.dart';

import 'utils/theme.dart';
import 'routes/app_router.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/logging_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';

class HealthInsightApp extends StatelessWidget {
  const HealthInsightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Insight Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const MainShell(),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

/// MainShell — Houses the bottom navigation bar and switches between
/// the five primary screens.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    LoggingScreen(),
    InsightsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: HealthBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
