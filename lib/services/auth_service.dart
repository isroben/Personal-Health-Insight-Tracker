/// ==========================================================================
/// auth_service.dart — Authentication Service (Firebase Auth)
/// ==========================================================================
/// Abstracts all Firebase Auth operations behind a clean API:
/// - Email/password sign-up and sign-in
/// - Sign out / password reset / delete account
/// - Auth state stream for reactive UI updates
///
/// ARCHITECTURE NOTE:
///   Firebase Auth still manages credentials (sign-up, sign-in, sign-out).
///   After authentication, [UserProfileRepository.verifyAuthToken] is called
///   to create/sync the user document on the backend (which then writes to
///   Firestore). This service no longer reads/writes Firestore directly.
///
///   The [authStateChanges] stream now builds [UserModel] from Firebase Auth
///   data alone — no Firestore read is needed in the client.
/// ==========================================================================

import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../models/user_model.dart';
import '../repositories/user_profile_repository.dart';

class AuthService {
  final fb.FirebaseAuth _auth;
  final UserProfileRepository _profileRepo;

  /// [overrideAuth] is for unit testing.
  AuthService({
    fb.FirebaseAuth? overrideAuth,
    required UserProfileRepository profileRepo,
  })  : _auth = overrideAuth ?? fb.FirebaseAuth.instance,
        _profileRepo = profileRepo;

  // ── Sign Up ──

  /// Creates a new user account with email and password.
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    await firebaseUser.updateDisplayName(name);

    // Initial profile creation in Firestore
    final user = _userModelFromFirebase(firebaseUser);
    await _profileRepo.updateProfile(
      userId: user.id,
      name: name,
    );

    return user;
  }

  // ── Sign In ──

  /// Signs in an existing user with email and password.
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    return _userModelFromFirebase(firebaseUser);
  }

  // ── Sign Out ──

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Auth State Stream ──

  /// Returns a reactive stream of the currently authenticated user.
  ///
  /// Emits [null] when the user signs out, and a [UserModel] when
  /// signed in. Built from Firebase Auth data only — no Firestore read.
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().map((fb.User? firebaseUser) {
      if (firebaseUser == null) return null;
      return _userModelFromFirebase(firebaseUser);
    });
  }

  // ── Current User (Sync) ──

  /// Returns the currently signed-in user synchronously.
  /// Uses Firebase Auth data only (no network call).
  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _userModelFromFirebase(firebaseUser);
  }

  // ── Password Reset ──

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Delete Account ──

  /// Deletes the Firebase Auth account.
  /// Note: backend cleanup (Firestore document, etc.) should be handled
  /// server-side via a dedicated API endpoint.
  Future<void> deleteAccount() async {
    await _auth.currentUser?.delete();
  }

  // ── Private Helpers ──

  /// Builds a [UserModel] from a Firebase Auth [User].
  /// Used as a fast path — no Firestore or API call needed.
  UserModel _userModelFromFirebase(fb.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      profilePhotoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
