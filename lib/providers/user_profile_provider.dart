/// ==========================================================================
/// user_profile_provider.dart — User Profile State Provider (Riverpod)
/// ==========================================================================
/// Manages user profile updates via the backend API.
///
/// ARCHITECTURE NOTE:
///   Profile operations now route through [UserProfileRepository]
///   → [ApiService] → Backend instead of writing Firestore directly.
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/user_profile_repository.dart';
import 'auth_provider.dart'; // userProfileRepositoryProvider

/// Manages profile update and delete operations.
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
  return UserProfileNotifier(
    ref.read(userProfileRepositoryProvider),
    ref,
  );
});

class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final UserProfileRepository _repo;
  final Ref _ref;

  UserProfileNotifier(this._repo, this._ref) : super(const AsyncData(null));

  /// Updates the user's profile via Firestore.
  Future<void> updateProfile({
    String? name,
    String? photoUrl,
    int? age,
    double? height,
    double? weight,
    String? gender,
    Map<String, dynamic>? preferences,
  }) async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = AsyncError(Exception('User not authenticated'), StackTrace.current);
      return;
    }

    state = const AsyncLoading();
    try {
      await _repo.updateProfile(
        userId: user.id,
        name: name,
        profilePhotoUrl: photoUrl,
        age: age,
        height: height,
        weight: weight,
        gender: gender,
        preferences: preferences,
      );
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Deletes the user account — signs out Firebase Auth.
  /// Backend cleanup (Firestore) is triggered server-side.
  /// Deletes the user account — requires password re-authentication.
  Future<void> deleteAccount(String password) async {
    state = const AsyncLoading();
    try {
      final authService = _ref.read(authServiceProvider);
      await authService.deleteAccount(password);
      await _ref.read(authActionsProvider.notifier).signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
