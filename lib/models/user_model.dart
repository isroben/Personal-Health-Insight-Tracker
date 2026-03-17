/// ==========================================================================
/// user_model.dart — User Entity
/// ==========================================================================
/// Represents an authenticated user in the app.
/// Fields: id, name, email, profile photo URL, subscription tier,
///         createdAt, updatedAt timestamps.
/// Stored in the Firestore `users` collection.
///
/// Serialization:
///   - [toMap] / [fromMap] for Firestore documents
///   - [toJson] / [fromJson] convenience wrappers (same format)
/// ==========================================================================

import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final SubscriptionTier subscription;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    this.subscription = SubscriptionTier.free,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Firestore Serialization ──

  /// Creates a [UserModel] from a Firestore document map.
  /// Handles both Timestamp and String date formats gracefully.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      subscription: SubscriptionTier.values.firstWhere(
        (e) => e.name == map['subscription'],
        orElse: () => SubscriptionTier.free,
      ),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  /// Converts to a Firestore-compatible map.
  /// Dates stored as ISO 8601 strings for cross-platform compatibility.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'subscription': subscription.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ── JSON Convenience ──

  /// Creates a [UserModel] from a JSON string.
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Serializes to a JSON string (useful for local cache).
  String toJson() => json.encode(toMap());

  // ── Copy ──

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhotoUrl,
    SubscriptionTier? subscription,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      subscription: subscription ?? this.subscription,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Subscription tiers controlling feature access.
enum SubscriptionTier {
  /// Free tier — basic logging, weekly summaries, limited reports.
  free,

  /// Premium tier — AI predictions, multi-factor correlations, advanced reports.
  premium,
}

// ── Helper ──

/// Parses a date from either an ISO 8601 string or a Firestore Timestamp.
DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  // Firestore Timestamp has a toDate() method
  if (value != null && value is! String) {
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
