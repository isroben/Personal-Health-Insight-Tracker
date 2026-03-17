/// ==========================================================================
/// validators.dart — Input Validation Logic
/// ==========================================================================
/// Centralized validation functions for all user inputs in the app.
///
/// Design:
///   - Each validator returns a nullable [String] — null means valid,
///     a non-null string is the user-facing error message
///   - This interface is compatible with Flutter Form's [validator] param
///   - All messages are concise and actionable
/// ==========================================================================

class AppValidators {
  // ══════════════════════════════════════════════════════════════════════════
  // ── Symptom Validators ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Validates that a symptom type has been selected.
  /// Returns an error string if null or empty, null if valid.
  static String? validateSymptomType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select at least one symptom.';
    }
    return null;
  }

  /// Validates symptom severity is an integer in the range [1, 10].
  ///
  /// Accepts either a [double] (from a slider) or [int].
  static String? validateSeverity(num? value) {
    if (value == null) {
      return 'Severity is required.';
    }
    final intVal = value.round();
    if (intVal < 1 || intVal > 10) {
      return 'Severity must be between 1 and 10.';
    }
    return null;
  }

  /// Validates optional symptom notes — just enforces a max length.
  static String? validateNotes(String? value) {
    if (value != null && value.length > 500) {
      return 'Notes must be 500 characters or fewer (${value.length}/500).';
    }
    return null; // Notes are optional
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Lifestyle Validators ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Validates sleep hours are within a realistic range [0, 24].
  static String? validateSleepHours(num? value) {
    if (value == null) return 'Sleep hours are required.';
    if (value < 0 || value > 24) {
      return 'Sleep hours must be between 0 and 24.';
    }
    return null;
  }

  /// Validates hydration glasses are a non-negative integer.
  static String? validateHydration(int? value) {
    if (value == null) return 'Hydration is required.';
    if (value < 0) return 'Hydration cannot be negative.';
    if (value > 30) return 'That seems too high — please double-check.';
    return null;
  }

  /// Validates exercise minutes are non-negative and realistic.
  static String? validateExerciseMinutes(int? value) {
    if (value == null) return 'Exercise minutes are required.';
    if (value < 0) return 'Exercise minutes cannot be negative.';
    if (value > 720) return 'That seems too high — please double-check.';
    return null;
  }

  /// Validates stress level is an integer in the range [1, 10].
  static String? validateStressLevel(num? value) {
    if (value == null) return 'Stress level is required.';
    final intVal = value.round();
    if (intVal < 1 || intVal > 10) {
      return 'Stress level must be between 1 and 10.';
    }
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Auth Validators ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Validates an email address format.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Validates a password for minimum strength requirements.
  ///
  /// Rules: at least 8 characters, one uppercase, one number.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Include at least one uppercase letter.';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Include at least one number.';
    }
    return null;
  }

  /// Validates that a display name is non-empty and reasonable length.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required.';
    if (value.trim().length < 2) return 'Name must be at least 2 characters.';
    if (value.trim().length > 60) return 'Name is too long.';
    return null;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Composite Log Validation ──
  // ══════════════════════════════════════════════════════════════════════════

  /// Validates a complete symptom log entry and returns a map of field errors.
  ///
  /// Returns an empty map if everything is valid.
  /// Keys match the field names used in the logging form.
  ///
  /// Usage:
  /// ```dart
  /// final errors = AppValidators.validateSymptomLogForm(
  ///   symptomType: selected,
  ///   severity: severitySliderValue,
  ///   notes: notesController.text,
  /// );
  /// if (errors.isEmpty) { // save the log }
  /// ```
  static Map<String, String> validateSymptomLogForm({
    required String? symptomType,
    required num? severity,
    String? notes,
  }) {
    final errors = <String, String>{};

    final symptomError = validateSymptomType(symptomType);
    if (symptomError != null) errors['symptomType'] = symptomError;

    final severityError = validateSeverity(severity);
    if (severityError != null) errors['severity'] = severityError;

    final notesError = validateNotes(notes);
    if (notesError != null) errors['notes'] = notesError;

    return errors;
  }

  /// Validates a complete lifestyle entry and returns a map of field errors.
  static Map<String, String> validateLifestyleForm({
    required num? sleepHours,
    required int? hydration,
    required int? exerciseMinutes,
    required num? stressLevel,
  }) {
    final errors = <String, String>{};

    final sleepError = validateSleepHours(sleepHours);
    if (sleepError != null) errors['sleepHours'] = sleepError;

    final hydrationError = validateHydration(hydration);
    if (hydrationError != null) errors['hydration'] = hydrationError;

    final exerciseError = validateExerciseMinutes(exerciseMinutes);
    if (exerciseError != null) errors['exerciseMinutes'] = exerciseError;

    final stressError = validateStressLevel(stressLevel);
    if (stressError != null) errors['stressLevel'] = stressError;

    return errors;
  }
}
