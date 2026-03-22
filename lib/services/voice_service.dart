import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  // Expose tts for SafetyService
  static FlutterTts getTts() => _tts;

  static Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  static Future<void> announceApproaching(
      double distanceMeters, double? etaMinutes) async {
    await initialize();
    String message;
    if (etaMinutes != null && etaMinutes > 0) {
      final mins = etaMinutes.toStringAsFixed(0);
      message =
          'Attention! Your stop is approaching in approximately $mins minutes. Get ready.';
    } else if (distanceMeters < 1000) {
      final meters = distanceMeters.toStringAsFixed(0);
      message =
          'Warning! Your destination is only $meters meters away. Wake up!';
    } else {
      final km = (distanceMeters / 1000).toStringAsFixed(1);
      message =
          'Your destination is $km kilometers away. Start getting ready.';
    }
    await _tts.speak(message);
  }

  static Future<void> announceArrival() async {
    await initialize();
    await _tts.speak(
        'Wake up! You have arrived near your destination. Please get off now!');
  }

  static Future<void> stop() async {
    await _tts.stop();
  }
}