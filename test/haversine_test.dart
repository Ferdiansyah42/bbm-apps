import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/core/constants/app_constants.dart';
import 'package:antrian_solar/core/utils/haversine_calculator.dart';

void main() {
  group('HaversineCalculator Tests (Blueprint Bab 5.1)', () {
    test('Calculate distance between identical coordinates should be 0', () {
      final double distance = HaversineCalculator.calculateDistance(
        lat1: AppConstants.defaultSpbnLatitude,
        lon1: AppConstants.defaultSpbnLongitude,
        lat2: AppConstants.defaultSpbnLatitude,
        lon2: AppConstants.defaultSpbnLongitude,
      );
      expect(distance, closeTo(0.0, 0.001));
    });

    test('isWithinGeofence should return true for exact SPBN coordinate', () {
      final bool inGeofence = HaversineCalculator.isWithinGeofence(
        userLat: AppConstants.defaultSpbnLatitude,
        userLon: AppConstants.defaultSpbnLongitude,
      );
      expect(inGeofence, isTrue);
    });

    test('isWithinGeofence should return false for coordinates far away (>100m)', () {
      // Offset by ~0.005 degrees latitude (~550 meters)
      final bool inGeofence = HaversineCalculator.isWithinGeofence(
        userLat: AppConstants.defaultSpbnLatitude + 0.005,
        userLon: AppConstants.defaultSpbnLongitude,
      );
      expect(inGeofence, isFalse);
    });
  });
}
