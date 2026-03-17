/// ==========================================================================
/// auth_service.dart — Authentication Service (Firebase Auth)
/// ==========================================================================
/// Abstracts all Firebase Auth operations behind a clean API:
/// - Email/password sign-up and sign-in
/// - Google Sign-In (optional, commented for now)
/// - Sign out
/// - Auth state stream for reactive UI updates
///
/// This service creates a Firestore user document on first sign-up
/// and maps Firebase User objects to our domain [UserModel].
///
/// Consumed by AuthProvider for Riverpod state management.
/// ==========================================================================

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_model.dart';

class AuthService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// Allow dependency injection for testing; uses real Firebase by default.
  AuthService({
    fb.FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  // ── Collection Reference ──

  /// Reference to the Firestore 'users' collection.
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  // ── Sign Up ──

  /// Creates a new user account with email and password.
  ///
  /// Steps:
  /// 1. Creates Firebase Auth credential
  /// 2. Builds a [UserModel] from the Auth result
  /// 3. Stores the user profile document in Firestore
  ///
  /// Returns [UserModel] on success, `null` on failure.
  /// Throws [fb.FirebaseAuthException] on auth errors.
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    // 1. Create the Firebase Auth account
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) return null;

    // 2. Update the display name on the Auth profile
    await firebaseUser.updateDisplayName(name);

    // 3. Build our domain model
    final now = DateTime.now();
    final user = UserModel(
      id: firebaseUser.uid,
      name: name,
      email: email,
      profilePhotoUrl: firebaseUser.photoURL,
      subscription: SubscriptionTier.free,
      createdAt: now,
      updatedAt: now,
    );

    // 4. Store the user document in Firestore
    await _usersCol.doc(user.id).set(user.toMap());

    return user;
  }

  // ── Sign In ──

  /// Signs in an existing user with email and password.
  ///
  /// Returns the corresponding [UserModel] from Firestore.
  /// Returns `null` if the Firestore document doesn't exist
  /// (should not happen in normal flow).
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

    // Fetch the full user profile from Firestore
    return _getUserFromFirestore(firebaseUser.uid);
  }

  // ── Sign Out ──

  /// Signs the current user out of Firebase Auth.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Auth State Stream ──

  /// Returns a reactive stream of the currently authenticated user.
  ///
  /// Emits `null` when the user signs out, and a [UserModel] when
  /// signed in. This stream is the backbone of the AuthProvider.
  Stream<UserModel?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((fb.User? firebaseUser) async {
      if (firebaseUser == null) return null;
      return _getUserFromFirestore(firebaseUser.uid);
    });
  }

  // ── Current User (Sync) ──

  /// Returns the currently signed-in user synchronously.
  /// Only uses Firebase Auth data (no Firestore fetch).
  /// Returns `null` if not signed in.
  UserModel? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    return UserModel(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      profilePhotoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(), // Placeholder — full data from Firestore
      updatedAt: DateTime.now(),
    );
  }

  // ── Update Profile ──

  /// Updates the user's profile in both Firebase Auth and Firestore.
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (name != null) {
      updates['name'] = name;
      await _auth.currentUser?.updateDisplayName(name);
    }
    if (photoUrl != null) {
      updates['profilePhotoUrl'] = photoUrl;
      await _auth.currentUser?.updatePhotoURL(photoUrl);
    }

    await _usersCol.doc(userId).update(updates);
  }

  // ── Password Reset ──

  /// Sends a password reset email to the specified address.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Delete Account ──

  /// Permanently deletes the user's auth account and Firestore document.
  /// Requires the user to have recently signed in (re-authentication
  /// may be needed).
  Future<void> deleteAccount(String userId) async {
    // Delete Firestore document first
    await _usersCol.doc(userId).delete();
    // Then delete the Auth account
    await _auth.currentUser?.delete();
  }

  // ── Private Helpers ──

  /// Fetches a [UserModel] from Firestore by UID.
  /// Returns `null` if the document doesn't exist.
  Future<UserModel?> _getUserFromFirestore(String uid) async {
    final doc = await _usersCol.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromMap(doc.data()!);
  }
}
