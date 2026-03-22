import 'package:geolocator/geolocator.dart';

class LocationService {
  // Checks GPS + permissions and returns a clear reason if something's wrong
  static Future<LocationResult> requestPermission() async {
    // Is the device GPS even turned on?
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult.failure(
        'Location services are turned off on your device. '
        'Please enable GPS in your phone settings.',
      );
    }

    // Check current permission status
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Ask the user for permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult.failure(
          'Location permission was denied. '
          'The app needs location access to monitor your journey.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult.failure(
        'Location permission is permanently denied. '
        'Please go to App Settings and enable location access manually.',
      );
    }

    // All good!
    return LocationResult.success();
  }

  // Get a one-time current position
  static Future<Position?> getCurrentPosition() async {
    final result = await requestPermission();
    if (!result.isSuccess) return null;

    try {
      return await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);
    } catch (e) {
      return null;
    }
  }

  // Calculate distance in meters between two coordinates
  static double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Continuous GPS stream — feeds live position updates to AlarmService
  static Stream<Position> getPositionStream() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // only emit if moved 10+ meters (saves battery)
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }
}

// A clean result object so callers know exactly what went wrong
class LocationResult {
  final bool isSuccess;
  final String? errorMessage;

  LocationResult._({required this.isSuccess, this.errorMessage});

  factory LocationResult.success() => LocationResult._(isSuccess: true);

  factory LocationResult.failure(String message) =>
      LocationResult._(isSuccess: false, errorMessage: message);
}