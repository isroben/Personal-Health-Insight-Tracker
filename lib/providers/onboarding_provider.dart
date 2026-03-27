import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_cache_service.dart';
import 'logging_provider.dart'; // localCacheServiceProvider

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final cache = ref.watch(localCacheServiceProvider);
  return OnboardingNotifier(cache);
});

class OnboardingNotifier extends StateNotifier<bool> {
  final LocalCacheService _cache;

  OnboardingNotifier(this._cache) : super(_cache.isOnboardingCompleted());

  Future<void> completeOnboarding() async {
    await _cache.setOnboardingCompleted(true);
    state = true;
  }
}
