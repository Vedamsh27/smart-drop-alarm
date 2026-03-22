import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../providers/alarm_provider.dart';
import 'voice_service.dart';

class DistanceService {
  static Timer? _pollingTimer;
  static bool _announced10km = false;
  static bool _announced5km = false;
  static bool _announced2km = false;

  static Future<void> startMonitoring(AlarmProvider provider) async {
    await stopMonitoring();
    _resetAnnouncements();
    _scheduleNextPoll(provider);
  }

  static Future<void> stopMonitoring() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    await VoiceService.stop();
  }

  static void _resetAnnouncements() {
    _announced10km = false;
    _announced5km = false;
    _announced2km = false;
  }

  static Duration _getPollingInterval(double distanceMeters) {
    if (distanceMeters > 10000) return const Duration(seconds: 60);
    if (distanceMeters > 5000) return const Duration(seconds: 20);
    return const Duration(seconds: 5);
  }

  static void _scheduleNextPoll(AlarmProvider provider) {
    final currentDistance = provider.currentDistanceMeters ?? 0;
    final interval = _getPollingInterval(currentDistance);
    _pollingTimer = Timer(interval, () async {
      await _poll(provider);
    });
  }

  static Future<void> _poll(AlarmProvider provider) async {
    if (!provider.isAlarmActive) return;
    if (!provider.hasDestination) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final speedMs = position.speed >= 0 ? position.speed : 0.0;
      provider.updateSpeed(speedMs);

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        provider.destinationLat!,
        provider.destinationLng!,
      );

      provider.updateDistance(distance);

      // Voice announcements at key distances
      if (distance <= 10000 && !_announced10km) {
        _announced10km = true;
        await VoiceService.announceApproaching(
            distance, provider.etaMinutes);
      } else if (distance <= 5000 && !_announced5km) {
        _announced5km = true;
        await VoiceService.announceApproaching(
            distance, provider.etaMinutes);
      } else if (distance <= 2000 && !_announced2km) {
        _announced2km = true;
        await VoiceService.announceApproaching(
            distance, provider.etaMinutes);
      }

      // Trigger alarm
      if (distance <= provider.effectiveRadius &&
          !provider.isAlarmTriggered) {
        provider.triggerAlarm();
        await VoiceService.announceArrival();
        return;
      }

      _scheduleNextPoll(provider);
    } catch (e) {
      _pollingTimer = Timer(const Duration(seconds: 15), () {
        _scheduleNextPoll(provider);
      });
    }
  }
}