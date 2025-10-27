/// Saved location model for frequently used places
class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final String? wifiSsid;
  final DateTime createdAt;

  SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radius = 100.0,
    this.wifiSsid,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create SavedLocation from database map
  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      radius: map['radius'] as double? ?? 100.0,
      wifiSsid: map['wifiSsid'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Convert SavedLocation to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'wifiSsid': wifiSsid,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
