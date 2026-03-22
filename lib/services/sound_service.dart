import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  static const _key = 'alarm_sound';

  static const List<Map<String, String>> availableSounds = [
    {'name': '🔔 Classic Alarm', 'file': 'sounds/alarm.mp3'},
    {'name': '📳 Buzzer Alarm', 'file': 'sounds/alarm_bell.mp3'},
    {'name': '📱 Digital Alarm', 'file': 'sounds/alarm_digital.mp3'},
  ];

  static Future<String> getSelectedSound() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) ?? 'sounds/alarm.mp3';
  }

  static Future<void> setSelectedSound(String file) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, file);
  }
}