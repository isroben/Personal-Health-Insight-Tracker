/// ==========================================================================
/// ai_insight_service.dart — AI & Statistical Insight Engine
/// ==========================================================================
/// Analyzes user logs to detect triggers and predict risks.
/// 
/// Levels of analysis:
/// 1. Statistical (MVP): Fast, local calculations via Pearson correlation.
/// 2. AI (Premium): OpenAI GPT API for plain-language interpretation.
/// 
/// Data flow:
///   Raw Logs → Data Normalization → Math Engine → LLM Prompt → JSON Insights
/// ==========================================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/symptom_log.dart';
import '../models/lifestyle_entry.dart';
import '../models/correlation.dart';
import '../utils/math_utils.dart';
import 'package:uuid/uuid.dart';

class AIInsightService {
  final String? _openAiApiKey;
  static const String _model = 'gpt-4o-mini';

  AIInsightService({String? apiKey}) : _openAiApiKey = apiKey;

  // ══════════════════════════════════════════════════════════════════════════
  // ── 1. Statistical Correlation (MVP) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Detects potential triggers by correlating symptom severity with 
  /// lifestyle factors over the past 30 days.
  List<Correlation> detectStatisticalCorrelations({
    required String userId,
    required List<SymptomLog> symptomLogs,
    required List<LifestyleEntry> lifestyleLogs,
  }) {
    if (symptomLogs.length < 5 || lifestyleLogs.length < 5) return [];

    final correlations = <Correlation>[];
    final uuid = const Uuid();

    // Group logs by symptom type
    final symptomsByType = <SymptomType, List<SymptomLog>>{};
    for (var log in symptomLogs) {
      symptomsByType.putIfAbsent(log.symptomType, () => []).add(log);
    }

    // Correlate each symptom with lifestyle factors
    symptomsByType.forEach((type, logs) {
      // Factors we analyze: Sleep, Stress, Hydration
      final factors = ['Sleep', 'Stress', 'Hydration'];
      
      for (var factor in factors) {
        final pair = _alignData(logs, lifestyleLogs, factor);
        if (pair.x.length < 5) continue;

        final r = MathUtils.pearsonCorrelation(pair.x, pair.y);
        
        // Only keep significant correlations (abs > 0.4)
        if (r.abs() >= 0.4) {
          correlations.add(Correlation(
            id: uuid.v4(),
            userId: userId,
            symptom: type,
            trigger: _getTriggerLabel(factor, r),
            frequency: pair.x.length,
            severityCorrelation: r.abs(),
            detectedAt: DateTime.now(),
            updatedAt: DateTime.now(),
            summary: 'Detected via statistical pattern analysis.',
          ));
        }
      }
    });

    return correlations;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── 2. AI Insights (Premium) ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Calls OpenAI to generate advanced insights and plain-language summaries.
  Future<List<Correlation>> generateAiInsights({
    required String userId,
    required List<SymptomLog> symptomLogs,
    required List<LifestyleEntry> lifestyleLogs,
  }) async {
    if (_openAiApiKey == null) throw Exception('API Key not configured');

    // 1. Prepare data summary for the prompt
    final dataContext = _formatDataForPrompt(symptomLogs, lifestyleLogs);

    // 2. Call OpenAI
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAiApiKey',
      },
      body: jsonEncode({
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a health data analyst. Analyze the following logs and return a JSON array of correlations. Each correlation must have: symptom_name, trigger_description, correlation_strength (0-1), and summary. Format: JSON only.'
          },
          {'role': 'user', 'content': dataContext}
        ],
        'response_format': {'type': 'json_object'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch AI insights: ${response.body}');
    }

    // 3. Parse JSON Response
    final decoded = jsonDecode(response.body);
    final content = decoded['choices'][0]['message']['content'];
    final List<dynamic> jsonList = jsonDecode(content)['correlations'];

    final uuid = const Uuid();
    return jsonList.map((j) {
      return Correlation(
        id: uuid.v4(),
        userId: userId,
        symptom: _mapStringToSymptom(j['symptom_name']),
        trigger: j['trigger_description'],
        frequency: symptomLogs.length,
        severityCorrelation: (j['correlation_strength'] as num).toDouble(),
        summary: j['summary'],
        detectedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Helpers ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Aligns symptom logs with lifestyle entries by date for math analysis.
  _DataPair _alignData(List<SymptomLog> sLogs, List<LifestyleEntry> lLogs, String factor) {
    final x = <num>[];
    final y = <num>[];

    for (var sl in sLogs) {
      // Find lifestyle entry for the same day
      final matchingL = lLogs.where((ll) => 
        ll.date.year == sl.date.year && 
        ll.date.month == sl.date.month && 
        ll.date.day == sl.date.day
      ).firstOrNull;

      if (matchingL != null) {
        x.add(sl.severity);
        if (factor == 'Sleep') y.add(matchingL.sleepHours);
        if (factor == 'Stress') y.add(matchingL.stressLevel);
        if (factor == 'Hydration') y.add(matchingL.hydrationGlasses);
      }
    }
    return _DataPair(x, y);
  }

  String _getTriggerLabel(String factor, double r) {
    if (factor == 'Sleep' && r < 0) return 'Low Sleep';
    if (factor == 'Stress' && r > 0) return 'High Stress';
    if (factor == 'Hydration' && r < 0) return 'Low Hydration';
    return '$factor Patterns';
  }

  String _formatDataForPrompt(List<SymptomLog> s, List<LifestyleEntry> l) {
    // Basic summary to avoid token waste
    final sb = StringBuffer();
    sb.writeln('Daily logs for 30 days:');
    for (var i = 0; i < s.length; i++) {
        sb.writeln('Day ${s[i].date.toIso8601String().substring(0,10)}: ${s[i].symptomType.name} sev=${s[i].severity}');
    }
    return sb.toString();
  }

  SymptomType _mapStringToSymptom(String name) {
    return SymptomType.values.firstWhere(
      (e) => e.name.toLowerCase() == name.toLowerCase(),
      orElse: () => SymptomType.other,
    );
  }
}

class _DataPair {
  final List<num> x;
  final List<num> y;
  _DataPair(this.x, this.y);
}
