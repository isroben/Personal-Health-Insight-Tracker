/// ==========================================================================
/// environmental_service.dart — Weather & Air Quality Service
/// ==========================================================================
/// Fetches context-aware data to help identify environmental triggers.
/// 
/// In a production app, this would use:
/// - OpenWeatherMap API for humidity/temp/pressure
/// - WAQI API for PM2.5 / Ozone
/// - Geolocator for user position
/// ==========================================================================

class EnvironmentalContext {
  final double temperature;
  final int humidity; // 0-100
  final int aqi; // 0-500
  final double pressure; // hPa

  EnvironmentalContext({
    required this.temperature,
    required this.humidity,
    required this.aqi,
    required this.pressure,
  });

  bool get isHighRiskAirQuality => aqi > 100;
  bool get isHighPressureChange => pressure < 1000 || pressure > 1025;
}

class EnvironmentalService {
  /// Fetches the current environmental context for the user's location.
  Future<EnvironmentalContext> getCurrentContext() async {
    // Mocking API call delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Sample data: High pressure/humidity often triggers migraines
    return EnvironmentalContext(
      temperature: 22.5,
      humidity: 85,
      aqi: 110, // Slightly unhealthy
      pressure: 1013.2,
    );
  }
}
