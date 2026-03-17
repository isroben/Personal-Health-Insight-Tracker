/// ==========================================================================
/// auth_provider.dart — Authentication State Provider (Riverpod)
/// ==========================================================================
/// Exposes reactive authentication state to the UI:
/// - Current user (UserModel or null)
/// - Auth loading/error states
/// - Sign-in / sign-up / sign-out actions
///
/// Depends on: AuthService
/// ==========================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provides a singleton instance of [AuthService].
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provides the current authenticated user as a stream.
/// Returns null when not signed in.
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Manages sign-in / sign-up actions with loading and error tracking.
final authActionsProvider =
    StateNotifierProvider<AuthActionsNotifier, AsyncValue<void>>((ref) {
  return AuthActionsNotifier(ref.read(authServiceProvider));
});

class AuthActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthActionsNotifier(this._authService) : super(const AsyncData(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await _authService.signIn(email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signUp(String name, String email, String password) async {
    state = const AsyncLoading();
    try {
      await _authService.signUp(name: name, email: email, password: password);
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }
}
