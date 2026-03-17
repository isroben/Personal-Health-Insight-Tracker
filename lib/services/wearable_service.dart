import 'package:health/health.dart';
import 'dart:io';

/// ==========================================================================
/// wearable_service.dart — Apple Health & Google Fit Integration
/// ==========================================================================
/// Handles automated data ingestion from wearable platforms.
/// Requires Info.plist/AndroidManifest.xml configuration for permissions.
/// ==========================================================================

class WearableService {
  final Health _health = Health();

  /// Requests authorization and fetches data for the last [days] days.
  Future<List<HealthDataPoint>> fetchWearableData({int days = 7}) async {
    final now = DateTime.now();
    final startTime = now.subtract(Duration(days: days));

    // Define the types to get.
    final types = [
      HealthDataType.STEPS,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.HEART_RATE,
      HealthDataType.WATER,
    ];

    // Request permissions
    bool requested = await _health.requestAuthorization(types);
    if (!requested) return [];

    // Fetch data
    List<HealthDataPoint> healthCache = await _health.getHealthDataFromTypes(
      startTime: startTime,
      endTime: now,
      types: types,
    );

    // Clean data (duplicates etc)
    return _health.removeDuplicates(healthCache);
  }

  /// Maps wearable sleep data to our internal LifestyleEntry format.
  double extractAverageSleep(List<HealthDataPoint> points) {
    final sleepPoints = points.where((p) => p.type == HealthDataType.SLEEP_ASLEEP);
    if (sleepPoints.isEmpty) return 0.0;
    
    // Simplification: sum durations for last 24h
    // In a real app, you'd group by day.
    return sleepPoints.fold(0.0, (sum, p) {
      final value = p.value as NumericHealthValue;
      return sum + (value.numericValue.toDouble() / 60); // Assuming minutes
    }) / 7; // Average over 7 days
  }
}
