import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProfileService {
  final FirebaseFirestore _db;

  UserProfileService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? photoUrl,
    HealthPreferences? preferences,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (name != null) updates['name'] = name;
    if (photoUrl != null) updates['profilePhotoUrl'] = photoUrl;
    if (preferences != null) updates['preferences'] = preferences.toMap();

    await _db.collection('users').doc(userId).update(updates);
  }

  Future<void> deleteUserData(String userId) async {
    final batch = _db.batch();
    
    // 1. Delete Symptom Logs
    final logs = await _db.collection('symptom_logs').where('userId', isEqualTo: userId).get();
    for (var doc in logs.docs) batch.delete(doc.reference);

    // 2. Delete Lifestyle Entries
    final entries = await _db.collection('lifestyle_entries').where('userId', isEqualTo: userId).get();
    for (var doc in entries.docs) batch.delete(doc.reference);

    // 3. Delete Correlations
    final correlations = await _db.collection('correlations').where('userId', isEqualTo: userId).get();
    for (var doc in correlations.docs) batch.delete(doc.reference);

    // 4. Delete User Profile last
    batch.delete(_db.collection('users').doc(userId));

    await batch.commit();
  }
}
