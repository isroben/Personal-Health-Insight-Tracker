/// ==========================================================================
/// insight.dart — Health Insight Model (API Layer)
/// ==========================================================================
/// Represents a health insight or correlation returned by the
/// GET /insights endpoint.
///
/// Insights are computed server-side and may include:
///   - Correlation insights: "Low sleep increases headache frequency"
///   - Trend insights:       "Your mood has been declining this week"
///   - Risk predictions:     "High dehydration risk tomorrow"
/// ==========================================================================

import 'dart:convert';

/// The category of insight.
enum InsightType {
  correlation,  // A detected pattern between two variables
  trend,        // A temporal trend in one or more variables
  prediction,   // A forward-looking risk estimate
  recommendation, // An actionable suggestion
}

class Insight {
  final String id;
  final InsightType type;
  final String title;          // Short, display-ready title
  final String description;    // Full explanation of the insight
  final double confidence;     // 0.0 – 1.0 (how confident the AI is)
  final String? triggerFactor; // e.g., "sleep", "hydration", "stress"
  final String? affectedSymptom; // e.g., "Headache", "Fatigue"
  final DateTime generatedAt;

  const Insight({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.confidence,
    this.triggerFactor,
    this.affectedSymptom,
    required this.generatedAt,
  });

  // ── JSON Serialization ──

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      id: json['id'] as String? ?? '',
      type: InsightType.values.firstWhere(
        (e) => e.name == (json['type'] as String? ?? 'correlation'),
        orElse: () => InsightType.correlation,
      ),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      triggerFactor: json['trigger_factor'] as String?,
      affectedSymptom: json['affected_symptom'] as String?,
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'confidence': confidence,
      if (triggerFactor != null) 'trigger_factor': triggerFactor,
      if (affectedSymptom != null) 'affected_symptom': affectedSymptom,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  String toJsonString() => json.encode(toJson());

  // ── Computed Properties ──

  /// Returns a human-readable confidence label.
  String get confidenceLabel {
    if (confidence >= 0.75) return 'High confidence';
    if (confidence >= 0.5) return 'Moderate confidence';
    return 'Low confidence';
  }

  @override
  String toString() => 'Insight(type: ${type.name}, title: $title)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Insight && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
