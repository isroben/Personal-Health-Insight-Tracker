/// ==========================================================================
/// subscription_provider.dart — Subscription State Management
/// ==========================================================================
/// Provides the subscription service and current access level to the UI.
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/subscription_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

/// Provides a boolean indicating if the current user has access to a specific feature.
final featureAccessProvider = Provider.family<bool, Feature>((ref, feature) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return false;
  
  return ref.read(subscriptionServiceProvider).canAccess(user, feature);
});

/// Action provider for handling purchases.
final subscriptionActionsProvider = StateNotifierProvider<SubscriptionActionsNotifier, AsyncValue<void>>((ref) {
  return SubscriptionActionsNotifier(ref.read(subscriptionServiceProvider), ref);
});

class SubscriptionActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final SubscriptionService _service;
  final Ref _ref;

  SubscriptionActionsNotifier(this._service, this._ref) : super(const AsyncData(null));

  Future<void> upgradeToPremium() async {
    state = const AsyncLoading();
    try {
      final success = await _service.purchasePremium();
      if (success) {
        // Refresh local user state if needed
        final user = _ref.read(authStateProvider).value;
        if (user != null) {
          await _service.syncSubscriptionStatus(user.id);
        }
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> restorePurchases() async {
    state = const AsyncLoading();
    try {
      await _service.restorePurchases();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
