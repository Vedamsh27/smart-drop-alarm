enum TransportMode { walking, cityBus, highway }

class PredictionService {
  // Speed thresholds in m/s
  static const double _walkingMax = 8.3;   // ~30 km/h
  static const double _cityBusMax = 16.7;  // ~60 km/h
  // above 16.7 m/s = highway (~60+ km/h)

  // Detect transport mode from speed
  static TransportMode detectMode(double speedMs) {
    if (speedMs < _walkingMax) return TransportMode.walking;
    if (speedMs < _cityBusMax) return TransportMode.cityBus;
    return TransportMode.highway;
  }

  // Auto radius based on speed (in meters)
  static double getSmartRadius(double speedMs) {
    final mode = detectMode(speedMs);
    switch (mode) {
      case TransportMode.highway:
        return 8000; // 8 km — need lots of warning at high speed
      case TransportMode.cityBus:
        return 5000; // 5 km
      case TransportMode.walking:
        return 2000; // 2 km — walking, no need for big radius
    }
  }

  // Calculate ETA in minutes based on distance and speed
  static double? getEtaMinutes(double distanceMeters, double speedMs) {
    if (speedMs < 0.5) return null; // not moving
    final seconds = distanceMeters / speedMs;
    return seconds / 60;
  }

  // Human readable mode label
  static String getModeLabel(TransportMode mode) {
    switch (mode) {
      case TransportMode.highway:
        return '🚄 Highway';
      case TransportMode.cityBus:
        return '🚌 City Bus';
      case TransportMode.walking:
        return '🚶 Walking';
    }
  }
}