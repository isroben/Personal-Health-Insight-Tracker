/// ==========================================================================
/// health_log.dart — Unified Health Log Model (API Layer)
/// ==========================================================================
/// A combined model for the POST /log-symptom and GET /health-history
/// API endpoints. Merges symptom and lifestyle data into a single entry
/// that the backend can process and store.
///
/// Unlike the split [SymptomLog] / [LifestyleEntry] used internally,
/// this model reflects the API's request/response contract.
/// ==========================================================================

import 'dart:convert';

class HealthLog {
  final String id;
  final String userId;
  final String symptom;       // e.g. "Headache", "Fatigue"
  final int severity;         // 1–10
  final double sleepHours;    // hours of sleep last night
  final double waterIntake;   // litres consumed
  final int exerciseMinutes;  // minutes of exercise
  final int screenTimeMinutes; // minutes of screen time
  final String mood;          // e.g. "good", "tired", "anxious"
  final int stressLevel;      // 1–10
  final String? notes;
  final DateTime createdAt;

  const HealthLog({
    required this.id,
    required this.userId,
    required this.symptom,
    required this.severity,
    required this.sleepHours,
    required this.waterIntake,
    required this.exerciseMinutes,
    required this.screenTimeMinutes,
    required this.mood,
    required this.stressLevel,
    this.notes,
    required this.createdAt,
  });

  // ── JSON Serialization (API contract) ──

  /// Builds a [HealthLog] from Firestore data or API JSON.
  factory HealthLog.fromJson(Map<String, dynamic> json) {
    return HealthLog(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] ?? '',
      symptom: json['symptom'] as String? ?? '',
      severity: (json['severity'] as num?)?.toInt() ?? 0,
      sleepHours: (json['sleep_hours'] as num?)?.toDouble() ?? 0.0,
      waterIntake: (json['water_intake'] as num?)?.toDouble() ?? 0.0,
      exerciseMinutes: (json['exercise_minutes'] as num?)?.toInt() ?? 0,
      screenTimeMinutes: (json['screen_time_minutes'] as num?)?.toInt() ?? 0,
      mood: json['mood'] as String? ?? '',
      stressLevel: (json['stress_level'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['date'] ?? json['created_at'] ?? json['createdAt']),
    );
  }

  /// Converts to a Map for Firestore storage, using Timestamps and proper snake_case keys.
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'user_id': userId,
      'symptom': symptom,
      'severity': severity,
      'sleep_hours': sleepHours,
      'water_intake': waterIntake,
      'exercise_minutes': exerciseMinutes,
      'screen_time_minutes': screenTimeMinutes,
      'mood': mood,
      'stress_level': stressLevel,
      if (notes != null) 'notes': notes,
      'date': createdAt, // This will be converted to a Timestamp by the Firestore SDK
      'created_at': createdAt, // Using Timestamp for both for ordering flexibility
    };
  }

  /// Converts to a Map for JSON storage.
  Map<String, dynamic> toJson() => toFirestoreMap();

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is String) return DateTime.parse(value);
    // Handle Firestore Timestamp if available (but avoid hard dependency on cloud_firestore in model if possible)
    // Actually, since this is a mobile app directly using Firestore, it's fine.
    try {
      return (value as dynamic).toDate() as DateTime;
    } catch (_) {
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  String toJsonString() => json.encode(toJson());

  HealthLog copyWith({
    String? id,
    String? userId,
    String? symptom,
    int? severity,
    double? sleepHours,
    double? waterIntake,
    int? exerciseMinutes,
    int? screenTimeMinutes,
    String? mood,
    int? stressLevel,
    String? notes,
    DateTime? createdAt,
  }) {
    return HealthLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symptom: symptom ?? this.symptom,
      severity: severity ?? this.severity,
      sleepHours: sleepHours ?? this.sleepHours,
      waterIntake: waterIntake ?? this.waterIntake,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      screenTimeMinutes: screenTimeMinutes ?? this.screenTimeMinutes,
      mood: mood ?? this.mood,
      stressLevel: stressLevel ?? this.stressLevel,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'HealthLog(symptom: $symptom, severity: $severity, date: $createdAt)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is HealthLog && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
