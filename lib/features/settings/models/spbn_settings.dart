import '../../../core/constants/app_constants.dart';

/// Model konfigurasi stasiun SPBN dan pengaturan Geofencing
class SpbnSettings {
  final bool isGeofenceEnabled; // Default false (Mode Bebas Uji)
  final String spbnName;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  const SpbnSettings({
    this.isGeofenceEnabled = false,
    this.spbnName = AppConstants.defaultSpbnName,
    this.latitude = AppConstants.defaultSpbnLatitude,
    this.longitude = AppConstants.defaultSpbnLongitude,
    this.radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
  });

  SpbnSettings copyWith({
    bool? isGeofenceEnabled,
    String? spbnName,
    double? latitude,
    double? longitude,
    double? radiusMeters,
  }) {
    return SpbnSettings(
      isGeofenceEnabled: isGeofenceEnabled ?? this.isGeofenceEnabled,
      spbnName: spbnName ?? this.spbnName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusMeters: radiusMeters ?? this.radiusMeters,
    );
  }
}
