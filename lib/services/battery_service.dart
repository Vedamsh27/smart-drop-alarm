import 'package:battery_plus/battery_plus.dart';

class BatteryService {
  static final Battery _battery = Battery();

  static Future<bool> isBatterySaverOn() async {
    try {
      return await _battery.isInBatterySaveMode;
    } catch (e) {
      return false;
    }
  }

  static Future<int> getBatteryLevel() async {
    try {
      return await _battery.batteryLevel;
    } catch (e) {
      return 100;
    }
  }
}