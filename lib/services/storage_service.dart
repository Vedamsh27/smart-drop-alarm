import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/alarm_model.dart';

class StorageService {
  static const String _alarmsKey = 'saved_alarms';

  // Save all alarms to local storage
  static Future<void> saveAlarms(List<AlarmModel> alarms) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> encoded =
        alarms.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList(_alarmsKey, encoded);
  }

  // Load all alarms from local storage
  static Future<List<AlarmModel>> loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? encoded = prefs.getStringList(_alarmsKey);
    if (encoded == null) return [];
    return encoded
        .map((e) => AlarmModel.fromJson(jsonDecode(e)))
        .toList();
  }

  // Add a single alarm
  static Future<void> addAlarm(AlarmModel alarm) async {
    final alarms = await loadAlarms();
    alarms.add(alarm);
    await saveAlarms(alarms);
  }

  // Delete alarm by id
  static Future<void> deleteAlarm(String id) async {
    final alarms = await loadAlarms();
    alarms.removeWhere((a) => a.id == id);
    await saveAlarms(alarms);
  }
}
