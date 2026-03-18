/// ==========================================================================
/// main.dart — Application Entry Point
/// ==========================================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 

import 'app.dart';
import 'services/local_cache_service.dart';
import 'services/app_bootstrap_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();

    // ── Resilient Firebase Initialization ──
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('Firebase initialized from Dart.');
      } else {
        debugPrint('Firebase already initialized by native system.');
      }
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        debugPrint('Firebase duplicate-app ignored.');
      } else {
        rethrow; // Rethrow other Firebase errors
      }
    }

    // ── Hive (Local Cache) Initialization ──
    await LocalCacheService.init();

    final container = ProviderContainer();

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const HealthInsightApp(),
      ),
    );

    // ── Non-blocking Bootstrap ──
    _backgroundBootstrap(container);

  } catch (e, stack) {
    debugPrint('Critical initialization error: $e');
    debugPrint(stack.toString());
    
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('$e', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Force restart app logic
                    main(); 
                  },
                  child: const Text('Retry Launch'),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

Future<void> _backgroundBootstrap(ProviderContainer container) async {
  try {
    final bootstrap = container.read(appBootstrapServiceProvider);
    await bootstrap.onAppLaunch();
    debugPrint('App Bootstrap complete.');
  } catch (e) {
    debugPrint('Background bootstrap error: $e');
  }
}
