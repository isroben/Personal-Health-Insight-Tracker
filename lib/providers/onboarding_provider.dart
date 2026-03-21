import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_cache_service.dart';
import 'logging_provider.dart'; // localCacheServiceProvider is defined here

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final cache = ref.read(localCacheServiceProvider);
  return OnboardingNotifier(cache);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final LocalCacheService _cache;
  OnboardingNotifier(this._cache) : super(_cache.isOnboardingCompleted());

  void completeOnboarding() {
    _cache.setOnboardingCompleted(true);
    state = true;
  }
}
