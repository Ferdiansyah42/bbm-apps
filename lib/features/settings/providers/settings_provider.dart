import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../models/spbn_settings.dart';

class SettingsNotifier extends Notifier<SpbnSettings> {
  static const String _keyGeofenceEnabled = 'setting_geofence_enabled';
  static const String _keySpbnName = 'setting_spbn_name';
  static const String _keySpbnLatitude = 'setting_spbn_lat';
  static const String _keySpbnLongitude = 'setting_spbn_lng';
  static const String _keySpbnRadius = 'setting_spbn_radius';

  @override
  SpbnSettings build() {
    _loadFromPrefs();
    // Default: Geofencing OFF (Mati) agar dapat diuji coba langsung dari rumah
    return const SpbnSettings(
      isGeofenceEnabled: false,
      spbnName: AppConstants.defaultSpbnName,
      latitude: AppConstants.defaultSpbnLatitude,
      longitude: AppConstants.defaultSpbnLongitude,
      radiusMeters: AppConstants.defaultGeofenceRadiusMeters,
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool(_keyGeofenceEnabled) ?? false;
      final name = prefs.getString(_keySpbnName) ?? AppConstants.defaultSpbnName;
      final lat = prefs.getDouble(_keySpbnLatitude) ?? AppConstants.defaultSpbnLatitude;
      final lng = prefs.getDouble(_keySpbnLongitude) ?? AppConstants.defaultSpbnLongitude;
      final radius = prefs.getDouble(_keySpbnRadius) ?? AppConstants.defaultGeofenceRadiusMeters;

      state = SpbnSettings(
        isGeofenceEnabled: isEnabled,
        spbnName: name,
        latitude: lat,
        longitude: lng,
        radiusMeters: radius,
      );
    } catch (_) {}
  }

  Future<void> setGeofenceEnabled(bool enabled) async {
    state = state.copyWith(isGeofenceEnabled: enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGeofenceEnabled, enabled);
    } catch (_) {}
  }

  Future<void> updateSettings({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String? spbnName,
  }) async {
    state = state.copyWith(
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      spbnName: spbnName,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keySpbnLatitude, latitude);
      await prefs.setDouble(_keySpbnLongitude, longitude);
      await prefs.setDouble(_keySpbnRadius, radiusMeters);
      if (spbnName != null) {
        await prefs.setString(_keySpbnName, spbnName);
      }
    } catch (_) {}
  }

  Future<void> resetToDefault() async {
    state = const SpbnSettings(
      isGeofenceEnabled: false,
      spbnName: AppConstants.defaultSpbnName,
      latitude: AppConstants.defaultSpbnLatitude,
      longitude: AppConstants.defaultSpbnLongitude,
      radiusMeters: AppConstants.defaultGeofenceRadiusMeters,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyGeofenceEnabled, false);
      await prefs.setDouble(_keySpbnLatitude, AppConstants.defaultSpbnLatitude);
      await prefs.setDouble(_keySpbnLongitude, AppConstants.defaultSpbnLongitude);
      await prefs.setDouble(_keySpbnRadius, AppConstants.defaultGeofenceRadiusMeters);
      await prefs.setString(_keySpbnName, AppConstants.defaultSpbnName);
    } catch (_) {}
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SpbnSettings>(
  SettingsNotifier.new,
);
