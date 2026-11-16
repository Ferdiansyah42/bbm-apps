import '../constants/app_constants.dart';

/// Model data stasiun SPBN sesuai skema spbn_stations pada Blueprint TA.
class SpbnStation {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final double stockLiters;
  final bool isOpen;
  final int activeQueueCount;

  const SpbnStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
    required this.stockLiters,
    this.isOpen = true,
    this.activeQueueCount = 0,
  });

  factory SpbnStation.fromJson(Map<String, dynamic> json) {
    return SpbnStation(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? AppConstants.defaultSpbnName,
      latitude: (json['latitude'] as num?)?.toDouble() ?? AppConstants.defaultSpbnLatitude,
      longitude: (json['longitude'] as num?)?.toDouble() ?? AppConstants.defaultSpbnLongitude,
      radiusMeters: (json['radius_meters'] as num?)?.toDouble() ?? AppConstants.defaultGeofenceRadiusMeters,
      stockLiters: (json['stock_liters'] as num?)?.toDouble() ?? 0.0,
      isOpen: json['is_open'] as bool? ?? true,
      activeQueueCount: json['active_queue_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'stock_liters': stockLiters,
      'is_open': isOpen,
      'active_queue_count': activeQueueCount,
    };
  }

  SpbnStation copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    double? radiusMeters,
    double? stockLiters,
    bool? isOpen,
    int? activeQueueCount,
  }) {
    return SpbnStation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      stockLiters: stockLiters ?? this.stockLiters,
      isOpen: isOpen ?? this.isOpen,
      activeQueueCount: activeQueueCount ?? this.activeQueueCount,
    );
  }
}
