import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProfileRepository {
  final FirebaseFirestore _db;

  UserProfileRepository({
    FirebaseFirestore? db,
  }) : _db = db ?? FirebaseFirestore.instance;

  // ══════════════════════════════════════════════════════════════════════════
  // ── Get Profile ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Fetches the user's profile directly from Firestore.
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    
    if (!doc.exists) return null;
    
    return UserModel.fromMap(_normalizeUserMap(doc.data()!));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Update Profile ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Updates the user's profile directly in Firestore.
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? profilePhotoUrl,
    int? age,
    double? height,
    double? weight,
    String? gender,
    Map<String, dynamic>? preferences,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
      if (name != null) 'name': name,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (age != null) 'age': age,
      if (height != null) 'height': height,
      if (weight != null) 'weight': weight,
      if (gender != null) 'gender': gender,
      if (preferences != null) 'preferences': preferences,
    };

    final docRef = _db.collection('users').doc(userId);
    await docRef.set(updates, SetOptions(merge: true));

    final updatedDoc = await docRef.get();
    return UserModel.fromMap(_normalizeUserMap(updatedDoc.data()!));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Private Helpers ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Normalizes Firestore data to model keys.
  Map<String, dynamic> _normalizeUserMap(Map<String, dynamic> raw) {
    return {
      'id': raw['id'] ?? raw['uid'] ?? '',
      'name': raw['name'] ?? '',
      'email': raw['email'] ?? '',
      'profilePhotoUrl': raw['profilePhotoUrl'],
      'age': raw['age'],
      'height': raw['height'],
      'weight': raw['weight'],
      'gender': raw['gender'],
      'subscription': raw['subscription'] ?? 'free',
      'preferences': raw['preferences'],
      'createdAt': _parseTimestamp(raw['createdAt']),
      'updatedAt': _parseTimestamp(raw['updatedAt']),
    };
  }

  String _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate().toIso8601String();
    }
    return timestamp?.toString() ?? DateTime.now().toIso8601String();
  }
}
