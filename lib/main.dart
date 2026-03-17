/// ==========================================================================
/// main.dart — Application Entry Point
/// ==========================================================================
/// Initializes Firebase, Hive (local cache), and wraps the app in a
/// Riverpod [ProviderScope] for global state management.
///
/// Boot sequence:
/// 1. Ensure Flutter bindings are initialized
/// 2. Initialize Firebase for auth and cloud storage
/// 3. Initialize Hive for local offline caching
/// 4. Launch app inside ProviderScope
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'services/local_cache_service.dart';
import 'services/app_bootstrap_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase Initialization ──
  // TODO: Uncomment after adding firebase config files
  //       (google-services.json / GoogleService-Info.plist)
  // await Firebase.initializeApp();

  // ── Hive (Local Cache) Initialization ──
  // Opens all cache boxes for offline-first data access.
  await LocalCacheService.init();

  // ── App Bootstrap (Notifications, Reminders, Sync) ──
  final container = ProviderContainer();
  await container.read(appBootstrapServiceProvider).onAppLaunch();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const HealthInsightApp(),
    ),
  );
}
