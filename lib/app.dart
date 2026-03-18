/// ==========================================================================
/// app.dart — Root Application Widget
/// ==========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/theme.dart';
import 'routes/app_router.dart';
import 'widgets/bottom_nav_bar.dart';
import 'screens/home_screen.dart';
import 'screens/log_history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/navigation_provider.dart';

class HealthInsightApp extends ConsumerWidget {
  const HealthInsightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Health Insight Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: authState.when(
        data: (user) => user == null ? const AuthScreen() : const MainShell(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('Auth Error: $e'))),
      ),
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}

/// MainShell — Houses the bottom navigation bar and switches between
/// the five primary screens.
class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  final List<Widget> _screens = const [
    HomeScreen(),
    LogHistoryScreen(),
    InsightsScreen(),
    ReportsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: HealthBottomNavBar(
        currentIndex: currentIndex,
        onTap: (index) => ref.read(bottomNavIndexProvider.notifier).state = index,
      ),
    );
  }
}
