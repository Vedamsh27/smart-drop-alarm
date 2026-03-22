import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentDestination {
  final double lat;
  final double lng;
  final String name;

  RecentDestination({
    required this.lat,
    required this.lng,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        'name': name,
      };

  factory RecentDestination.fromJson(Map<String, dynamic> json) =>
      RecentDestination(
        lat: json['lat'],
        lng: json['lng'],
        name: json['name'],
      );
}

class RecentDestinationsService {
  static const _key = 'recent_destinations';
  static const _maxCount = 5;

  static Future<List<RecentDestination>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getStringList(_key) ?? [];
    return encoded
        .map((e) => RecentDestination.fromJson(jsonDecode(e)))
        .toList();
  }

  static Future<void> add(RecentDestination destination) async {
    final prefs = await SharedPreferences.getInstance();
    final recents = await load();

    // Remove duplicate if same name exists
    recents.removeWhere((r) => r.name == destination.name);

    // Add to front
    recents.insert(0, destination);

    // Keep only last 5
    final trimmed = recents.take(_maxCount).toList();

    final encoded = trimmed.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}