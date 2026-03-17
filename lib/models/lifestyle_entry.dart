/// ==========================================================================
/// lifestyle_entry.dart — Lifestyle Entry Entity
/// ==========================================================================
/// Represents a daily lifestyle log: sleep, diet, hydration, exercise, stress.
/// One entry per user per day. Stored in the Firestore
/// `lifestyle_entries` collection.
///
/// The composite key for upsert is [userId + dateKey], where dateKey is
/// the date formatted as 'yyyy-MM-dd' to enforce one entry per day.
/// ==========================================================================

import 'dart:convert';

class LifestyleEntry {
  final String id;
  final String userId;
  final DateTime date;
  final double sleepHours; // 0.0 – 24.0
  final DietQuality diet;
  final int hydrationGlasses; // number of glasses of water
  final int exerciseMinutes; // minutes of exercise
  final int stressLevel; // 1 (relaxed) to 10 (extremely stressed)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LifestyleEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.sleepHours,
    required this.diet,
    required this.hydrationGlasses,
    required this.exerciseMinutes,
    required this.stressLevel,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Returns a date-only key for upsert logic (e.g., "2024-10-12").
  /// Used to enforce one lifestyle entry per user per day.
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';

  // ── Firestore Serialization ──

  factory LifestyleEntry.fromMap(Map<String, dynamic> map) {
    return LifestyleEntry(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: _parseDate(map['date']),
      sleepHours: (map['sleepHours'] as num).toDouble(),
      diet: DietQuality.values.firstWhere(
        (e) => e.name == map['diet'],
        orElse: () => DietQuality.fair,
      ),
      hydrationGlasses: map['hydrationGlasses'] as int,
      exerciseMinutes: map['exerciseMinutes'] as int,
      stressLevel: map['stressLevel'] as int,
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'dateKey': dateKey,
      'sleepHours': sleepHours,
      'diet': diet.name,
      'hydrationGlasses': hydrationGlasses,
      'exerciseMinutes': exerciseMinutes,
      'stressLevel': stressLevel,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ── JSON Convenience ──

  factory LifestyleEntry.fromJson(String source) =>
      LifestyleEntry.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  // ── Copy ──

  LifestyleEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    double? sleepHours,
    DietQuality? diet,
    int? hydrationGlasses,
    int? exerciseMinutes,
    int? stressLevel,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LifestyleEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      sleepHours: sleepHours ?? this.sleepHours,
      diet: diet ?? this.diet,
      hydrationGlasses: hydrationGlasses ?? this.hydrationGlasses,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      stressLevel: stressLevel ?? this.stressLevel,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'LifestyleEntry(id: $id, date: $dateKey, sleep: $sleepHours hrs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LifestyleEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Subjective diet quality for the day.
enum DietQuality {
  poor,
  fair,
  good,
  excellent,
}

/// Extension to get display-friendly labels for DietQuality.
extension DietQualityDisplay on DietQuality {
  String get displayName {
    switch (this) {
      case DietQuality.poor:
        return 'Poor';
      case DietQuality.fair:
        return 'Fair';
      case DietQuality.good:
        return 'Good';
      case DietQuality.excellent:
        return 'Excellent';
    }
  }

  /// Returns an emoji icon for quick visual representation.
  String get emoji {
    switch (this) {
      case DietQuality.poor:
        return '🔴';
      case DietQuality.fair:
        return '🟠';
      case DietQuality.good:
        return '🟢';
      case DietQuality.excellent:
        return '🌟';
    }
  }
}

// ── Helper ──

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
