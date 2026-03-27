/// ==========================================================================
/// user_model.dart — User Entity
/// ==========================================================================
import 'dart:convert';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? profilePhotoUrl;
  final int? age;
  final double? height;
  final double? weight;
  final String? gender;
  final SubscriptionTier subscription;
  final HealthPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.profilePhotoUrl,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.subscription = SubscriptionTier.free,
    this.preferences = const HealthPreferences(),
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      name: map['name'] as String,
      email: map['email'] as String,
      profilePhotoUrl: map['profilePhotoUrl'] as String?,
      age: map['age'] as int?,
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      gender: map['gender'] as String?,
      subscription: SubscriptionTier.values.firstWhere(
        (e) => e.name == (map['subscription'] ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      preferences: map['preferences'] != null 
          ? HealthPreferences.fromMap(map['preferences'] as Map<String, dynamic>)
          : const HealthPreferences(),
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'subscription': subscription.name,
      'preferences': preferences.toMap(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? profilePhotoUrl,
    int? age,
    double? height,
    double? weight,
    String? gender,
    SubscriptionTier? subscription,
    HealthPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      subscription: subscription ?? this.subscription,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

class HealthPreferences {
  final String primaryCondition;
  final MeasurementUnit unit;
  final bool notificationsEnabled;
  final bool cloudSyncEnabled;

  const HealthPreferences({
    this.primaryCondition = 'General Wellness',
    this.unit = MeasurementUnit.metric,
    this.notificationsEnabled = true,
    this.cloudSyncEnabled = true,
  });

  factory HealthPreferences.fromMap(Map<String, dynamic> map) {
    return HealthPreferences(
      primaryCondition: map['primaryCondition'] as String? ?? 'General Wellness',
      unit: MeasurementUnit.values.firstWhere(
        (e) => e.name == (map['unit'] ?? 'metric'),
        orElse: () => MeasurementUnit.metric,
      ),
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      cloudSyncEnabled: map['cloudSyncEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryCondition': primaryCondition,
      'unit': unit.name,
      'notificationsEnabled': notificationsEnabled,
      'cloudSyncEnabled': cloudSyncEnabled,
    };
  }

  HealthPreferences copyWith({
    String? primaryCondition,
    MeasurementUnit? unit,
    bool? notificationsEnabled,
    bool? cloudSyncEnabled,
  }) {
    return HealthPreferences(
      primaryCondition: primaryCondition ?? this.primaryCondition,
      unit: unit ?? this.unit,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
    );
  }
}

enum SubscriptionTier { free, premium }
enum MeasurementUnit { metric, imperial }

DateTime _parseDate(dynamic value) {
  if (value is String) return DateTime.parse(value);
  if (value != null && value is! String) {
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      return DateTime.now();
    }
  }
  return DateTime.now();
}
