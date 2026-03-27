/// ==========================================================================
/// app.dart — Root Application Widget
/// ==========================================================================
/// CONNECTIVITY GUARD:
///   The app is API-driven and requires internet connectivity.
///   [connectivityProvider] watches the network status; if offline,
///   [NoInternetScreen] is shown in place of all other content.
/// ==========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'utils/theme.dart';
import 'routes/app_router.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/no_internet_screen.dart';
import 'screens/home_screen.dart';
import 'screens/log_history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'providers/auth_provider.dart';
import 'providers/connectivity_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/onboarding_provider.dart';
import 'providers/app_preferences_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_screen.dart';

class HealthInsightApp extends ConsumerWidget {
  const HealthInsightApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ── Connectivity guard — must be online to use the app ──
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOnline = connectivityAsync.valueOrNull ?? true;

    // While connectivity status is loading (first check), proceed optimistically.
    // Once we have a definitive offline signal, show the wall screen.
    final prefsState = ref.watch(appPreferencesProvider);

    if (!isOnline) {
      return MaterialApp(
        title: 'Health Insight Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: prefsState.themeMode,
        locale: prefsState.locale,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(prefsState.textScaleFactor),
          ),
          child: child!,
        ),
        home: const NoInternetScreen(),
      );
    }

    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Health Insight Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: prefsState.themeMode,
      locale: prefsState.locale,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(prefsState.textScaleFactor),
        ),
        child: child!,
      ),
      home: authState.when(
        data: (user) {
          final onboardingCompleted = ref.watch(onboardingProvider);
          if (!onboardingCompleted) return const OnboardingScreen();
          return user == null ? const AuthScreen() : const MainShell();
        },
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
