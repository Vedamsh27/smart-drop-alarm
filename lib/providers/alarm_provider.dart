import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/alarm_service.dart';
import '../screens/alarm_screen.dart';
import '../services/prediction_service.dart';
import '../services/safety_service.dart';


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class AlarmProvider extends ChangeNotifier {
  double? destinationLat;
  double? destinationLng;
  String destinationName = '';
  double radiusInMeters = 5000;
  bool isAlarmActive = false;
  bool isAlarmTriggered = false;
  double? currentDistanceMeters;

  // Smart prediction state
  double? currentSpeedMs;
  TransportMode? transportMode;
  double? etaMinutes;
  bool useSmartRadius = true; // user can toggle this

  static const _keyLat = 'dest_lat';
  static const _keyLng = 'dest_lng';
  static const _keyName = 'dest_name';
  static const _keyRadius = 'radius';
  static const _keySmartRadius = 'smart_radius';

  Future<void> loadSavedState() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(_keyLat);
    final lng = prefs.getDouble(_keyLng);
    final name = prefs.getString(_keyName) ?? '';
    final radius = prefs.getDouble(_keyRadius) ?? 5000;
    final smart = prefs.getBool(_keySmartRadius) ?? true;
    if (lat != null && lng != null) {
      destinationLat = lat;
      destinationLng = lng;
      destinationName = name;
    }
    radiusInMeters = radius;
    useSmartRadius = smart;
    notifyListeners();
  }

  Future<void> setDestination(double lat, double lng, String name) async {
    destinationLat = lat;
    destinationLng = lng;
    destinationName = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLng, lng);
    await prefs.setString(_keyName, name);
  }

  Future<void> setRadius(double meters) async {
    radiusInMeters = meters;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyRadius, meters);
  }

  Future<void> toggleSmartRadius(bool value) async {
    useSmartRadius = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartRadius, value);
  }

  // Called from distance service with latest GPS position
  void updateSpeed(double speedMs) {
    currentSpeedMs = speedMs;
    transportMode = PredictionService.detectMode(speedMs);

    // Auto adjust radius if smart mode is on
    if (useSmartRadius && isAlarmActive) {
      final smartR = PredictionService.getSmartRadius(speedMs);
      radiusInMeters = smartR;
    }

    // Update ETA
    if (currentDistanceMeters != null) {
      etaMinutes = PredictionService.getEtaMinutes(
          currentDistanceMeters!, speedMs);
    }

    notifyListeners();
  }

  void startAlarm() {
    isAlarmActive = true;
    isAlarmTriggered = false;
    notifyListeners();
  }

 void stopAlarm() {
  isAlarmActive = false;
  isAlarmTriggered = false;
  currentSpeedMs = null;
  transportMode = null;
  etaMinutes = null;
  notifyListeners();
  // Cancel safety watch when user responds
  SafetyService.cancel();
}
// Snooze — silence alarm but keep monitoring active
void snooze() {
  isAlarmTriggered = false; // allows alarm to re-trigger
  isAlarmActive = true;     // keeps GPS monitoring alive
  notifyListeners();
}

void triggerAlarm() {
  if (!isAlarmTriggered) {
    isAlarmTriggered = true;
    notifyListeners();
    AlarmService.triggerAlarm();
    // Start safety watch — escalates if user doesn't respond
    SafetyService.startUnresponsiveWatch();
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const AlarmScreen()),
    );
  }
}

  void updateDistance(double meters) {
    currentDistanceMeters = meters;
    if (currentSpeedMs != null) {
      etaMinutes = PredictionService.getEtaMinutes(meters, currentSpeedMs!);
    }
    notifyListeners();
  }

  bool get hasDestination =>
      destinationLat != null && destinationLng != null;

  // Effective radius — smart or manual
  double get effectiveRadius => radiusInMeters;
}