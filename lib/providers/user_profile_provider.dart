import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_profile_service.dart';
import 'auth_provider.dart';

final userProfileServiceProvider = Provider<UserProfileService>((ref) {
  return UserProfileService();
});

final userProfileNotifierProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier(ref.read(userProfileServiceProvider), ref);
});

class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final UserProfileService _service;
  final Ref _ref;

  UserProfileNotifier(this._service, this._ref) : super(const AsyncData(null));

  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    HealthPreferences? preferences,
  }) async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) throw Exception('No user logged in');

      await _service.updateProfile(
        userId: user.id,
        name: name,
        photoUrl: photoUrl,
        preferences: preferences,
      );
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deleteAccount() async {
    state = const AsyncLoading();
    try {
      final user = _ref.read(authStateProvider).value;
      if (user == null) throw Exception('No user logged in');

      await _service.deleteUserData(user.id);
      await _ref.read(authActionsProvider.notifier).signOut();
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
