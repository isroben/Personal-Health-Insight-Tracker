/// ==========================================================================
/// no_internet_screen.dart — Offline Wall Screen
/// ==========================================================================
/// Shown when the device has no internet connection.
/// The app is API-driven and requires connectivity to function.
/// ==========================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connectivity_provider.dart';

class NoInternetScreen extends ConsumerWidget {
  const NoInternetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Icon ──
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.wifi_off_rounded,
                    size: 52,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 32),

                // ── Title ──
                Text(
                  'Internet Required',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // ── Subtitle ──
                Text(
                  'This app requires an internet connection to sync your health '
                  'data securely. Please check your network and try again.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // ── Retry Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Trigger a connectivity refresh by invalidating the provider
                      ref.invalidate(connectivityProvider);
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry Connection'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
