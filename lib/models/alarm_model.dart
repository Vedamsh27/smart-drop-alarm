class AlarmModel {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius; // in meters
  bool isActive;

  AlarmModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 200,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'isActive': isActive,
    };
  }

  factory AlarmModel.fromJson(Map<String, dynamic> json) {
    return AlarmModel(
      id: json['id'],
      name: json['name'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      radius: json['radius'] ?? 200,
      isActive: json['isActive'] ?? true,
    );
  }
}
