import 'dart:math' as math;
import '../constants/app_constants.dart';

/// Kalkulator jarak permukaan bumi menggunakan Haversine Formula
/// Sesuai spesifikasi matematis Blueprint TA Bab 5.1 (R_bumi = 6.371.000 m).
class HaversineCalculator {
  HaversineCalculator._();

  /// Menghitung jarak permukaan bumi presisi (dalam meter) antara dua koordinat geografis.
  /// Formula:
  ///   a = sin²(Δφ / 2) + cos(φ1) · cos(φ2) · sin²(Δλ / 2)
  ///   d = 2 · R_bumi · arcsin(min(1, √a))
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double phi1 = _toRadians(lat1);
    final double phi2 = _toRadians(lat2);
    final double deltaPhi = _toRadians(lat2 - lat1);
    final double deltaLambda = _toRadians(lon2 - lon1);

    final double sinHalfDeltaPhi = math.sin(deltaPhi / 2.0);
    final double sinHalfDeltaLambda = math.sin(deltaLambda / 2.0);

    final double a = (sinHalfDeltaPhi * sinHalfDeltaPhi) +
        (math.cos(phi1) * math.cos(phi2) * sinHalfDeltaLambda * sinHalfDeltaLambda);

    final double clampedA = math.min(1.0, math.max(0.0, a));
    final double distance = 2.0 * AppConstants.earthRadiusMeters * math.asin(math.sqrt(clampedA));

    return distance;
  }

  /// Alias metode langsung dengan parameter posisi
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return calculateDistance(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2);
  }

  /// Memvalidasi apakah posisi pengguna berada di dalam batas radius geofence SPBN (d <= Rspbn).
  static bool isWithinGeofence({
    required double userLat,
    required double userLon,
    double spbnLat = AppConstants.defaultSpbnLatitude,
    double spbnLon = AppConstants.defaultSpbnLongitude,
    double radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
  }) {
    final double distance = calculateDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: spbnLat,
      lon2: spbnLon,
    );
    return distance <= radiusMeters;
  }

  /// Menghitung arah/sudut kompas (bearing dalam derajat 0 - 360) dari pengguna ke SPBN
  static double calculateBearing({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double phi1 = _toRadians(lat1);
    final double phi2 = _toRadians(lat2);
    final double deltaLambda = _toRadians(lon2 - lon1);

    final double y = math.sin(deltaLambda) * math.cos(phi2);
    final double x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);
    final double theta = math.atan2(y, x);

    return (_toDegrees(theta) + 360.0) % 360.0;
  }

  static double _toRadians(double degree) => degree * (math.pi / 180.0);
  static double _toDegrees(double radian) => radian * (180.0 / math.pi);
}
