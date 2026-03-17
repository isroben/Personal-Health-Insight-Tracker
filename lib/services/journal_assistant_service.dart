import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// ==========================================================================
/// journal_assistant_service.dart — AI Journaling Assistant
/// ==========================================================================
/// Provides "Smart Journaling" capabilities:
/// 1. Voice-to-Symptom parsing (simulated with Gemini).
/// 2. Photo analysis for trigger tagging (e.g. food, environment).
/// ==========================================================================

class JournalAssistantService {
  final GenerativeModel _model;
  final ImagePicker _picker = ImagePicker();

  JournalAssistantService({String? apiKey}) 
    : _model = GenerativeModel(
        model: 'gemini-1.5-flash', 
        apiKey: apiKey ?? 'YOUR_GEMINI_API_KEY_HERE'
      );

  /// Processes natural language voice transcript into structured symptom data.
  /// Example input: "I have a sharp headache and I'm feeling a bit nauseous after lunch."
  /// Expected output: JSON with symptoms, severity, and potential triggers.
  Future<String> parseVoiceTranscript(String transcript) async {
    final prompt = '''
      You are a medical data parser. Convert the following patient journal entry into a JSON object.
      Entry: "$transcript"
      Format:
      {
        "symptoms": [{"name": String, "severity": 1-10}],
        "triggers": [String],
        "summary": String
      }
    ''';

    final content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    return response.text ?? '{"error": "Could not parse entry"}';
  }

  /// Analyzes a photo to detect health-relevant triggers (e.g., specific foods like dairy/gluten).
  Future<String> analyzePhoto(XFile photo) async {
    final bytes = await photo.readAsBytes();
    
    final prompt = [
      DataPart('image/jpeg', bytes),
      TextPart('Analyze this photo for potential health triggers. Focus on ingredients like dairy, caffeine, or specific allergens if this is food, or environmental factors like pollen or dust if it is a room/outdoor.')
    ];

    final response = await _model.generateContent([Content.multi(prompt)]);
    return response.text ?? 'No triggers identified.';
  }

  /// Convenience method to pick an image for analysis.
  Future<XFile?> pickImage() async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }
}
