import 'dart:math' as math;
import '../constants/app_constants.dart';

/// Kalkulator jarak permukaan bumi menggunakan Haversine Formula
/// Sesuai spesifikasi matematis Blueprint TA Bab 5.1 (R_bumi = 6.371.000 m).
class HaversineCalculator {
  HaversineCalculator._();

  /// Menghitung jarak permukaan bumi (dalam meter) antara posisi pengguna dan titik SPBN.
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

  static double _toRadians(double degree) => degree * (math.pi / 180.0);
}
