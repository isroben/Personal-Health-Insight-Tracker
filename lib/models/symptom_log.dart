/// ==========================================================================
/// symptom_log.dart — Symptom Log Entity
/// ==========================================================================
/// Represents a single symptom entry logged by the user.
/// Fields: id, userId, date, symptomType, severity (1–10), notes,
///         createdAt, updatedAt.
/// Stored in the Firestore `symptom_logs` collection.
///
/// Each log is uniquely identified by [id] (UUID) and belongs to a
/// user via [userId]. Severity is an integer scale from 1 (mild) to
/// 10 (severe).
/// ==========================================================================

import 'dart:convert';

class SymptomLog {
  final String id;
  final String userId;
  final DateTime date;
  final SymptomType symptomType;
  final int severity; // 1 (mild) to 10 (severe)
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SymptomLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.symptomType,
    required this.severity,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Firestore Serialization ──

  /// Creates a [SymptomLog] from a Firestore document map.
  factory SymptomLog.fromMap(Map<String, dynamic> map) {
    return SymptomLog(
      id: map['id'] as String,
      userId: map['userId'] as String,
      date: _parseDate(map['date']),
      symptomType: SymptomType.values.firstWhere(
        (e) => e.name == map['symptomType'],
        orElse: () => SymptomType.other,
      ),
      severity: map['severity'] as int,
      notes: map['notes'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  /// Converts to a Firestore-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'symptomType': symptomType.name,
      'severity': severity,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // ── JSON Convenience ──

  factory SymptomLog.fromJson(String source) =>
      SymptomLog.fromMap(json.decode(source) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  // ── Copy ──

  SymptomLog copyWith({
    String? id,
    String? userId,
    DateTime? date,
    SymptomType? symptomType,
    int? severity,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SymptomLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      symptomType: symptomType ?? this.symptomType,
      severity: severity ?? this.severity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() =>
      'SymptomLog(id: $id, symptom: ${symptomType.name}, severity: $severity)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SymptomLog && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Supported symptom categories.
/// Expand this enum as the app grows to cover more conditions.
enum SymptomType {
  headache,
  migraine,
  fatigue,
  nausea,
  bloating,
  stomachPain,
  jointPain,
  musclePain,
  dizziness,
  brainFog,
  anxiety,
  moodSwing,
  insomnia,
  skinIrritation,
  stress,
  pain,
  fever,
  cough,
  coldFlu,
  muscleSoreness,
  chestDiscomfort,
  shortnessOfBreath,
  allergySymptoms,
  eyeStrain,
  backPain,
  sleepiness,
  lowEnergy,
  happy,
  calm,
  motivated,
  focused,
  relaxed,
  anxious,
  irritated,
  overwhelmed,
  sad,
  burnout,
  confident,
  grateful,
  other,
}

/// Extension to get a user-friendly display name for each symptom type.
extension SymptomTypeDisplay on SymptomType {
  /// Returns a display-friendly label like "Stomach Pain" for stomachPain.
  String get displayName {
    switch (this) {
      case SymptomType.headache: return 'Headache';
      case SymptomType.migraine: return 'Migraine';
      case SymptomType.fatigue: return 'Fatigue';
      case SymptomType.nausea: return 'Nausea';
      case SymptomType.bloating: return 'Bloating';
      case SymptomType.stomachPain: return 'Stomach Pain';
      case SymptomType.jointPain: return 'Joint Pain';
      case SymptomType.musclePain: return 'Muscle Pain';
      case SymptomType.dizziness: return 'Dizziness';
      case SymptomType.brainFog: return 'Brain Fog';
      case SymptomType.anxiety: return 'Anxiety';
      case SymptomType.moodSwing: return 'Mood Swing';
      case SymptomType.insomnia: return 'Insomnia';
      case SymptomType.skinIrritation: return 'Skin Irritation';
      case SymptomType.stress: return 'Stress';
      case SymptomType.pain: return 'Pain';
      case SymptomType.fever: return 'Fever';
      case SymptomType.cough: return 'Cough';
      case SymptomType.coldFlu: return 'Cold / Flu symptoms';
      case SymptomType.muscleSoreness: return 'Muscle soreness';
      case SymptomType.chestDiscomfort: return 'Chest discomfort';
      case SymptomType.shortnessOfBreath: return 'Shortness of breath';
      case SymptomType.allergySymptoms: return 'Allergy symptoms';
      case SymptomType.eyeStrain: return 'Eye strain';
      case SymptomType.backPain: return 'Back pain';
      case SymptomType.sleepiness: return 'Sleepiness';
      case SymptomType.lowEnergy: return 'Low energy';
      case SymptomType.happy: return 'Happy';
      case SymptomType.calm: return 'Calm';
      case SymptomType.motivated: return 'Motivated';
      case SymptomType.focused: return 'Focused';
      case SymptomType.relaxed: return 'Relaxed';
      case SymptomType.anxious: return 'Anxious';
      case SymptomType.irritated: return 'Irritated';
      case SymptomType.overwhelmed: return 'Overwhelmed';
      case SymptomType.sad: return 'Sad';
      case SymptomType.burnout: return 'Burnout feeling';
      case SymptomType.confident: return 'Confident';
      case SymptomType.grateful: return 'Grateful';
      case SymptomType.other: return 'Other';
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
