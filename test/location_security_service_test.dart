import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:antrian_solar/core/constants/app_constants.dart';
import 'package:antrian_solar/core/security/location_security_service.dart';
import 'package:antrian_solar/core/utils/haversine_calculator.dart';

void main() {
  group('HaversineCalculator Precision Tests', () {
    test('calculateDistanceMeters matches calculateDistance', () {
      final d1 = HaversineCalculator.calculateDistance(
        lat1: AppConstants.defaultSpbnLatitude,
        lon1: AppConstants.defaultSpbnLongitude,
        lat2: -7.240000,
        lon2: 113.536000,
      );
      final d2 = HaversineCalculator.calculateDistanceMeters(
        AppConstants.defaultSpbnLatitude,
        AppConstants.defaultSpbnLongitude,
        -7.240000,
        113.536000,
      );
      expect(d1, equals(d2));
      expect(d1, greaterThan(0.0));
    });

    test('calculateBearing returns valid degree between 0 and 360', () {
      final bearing = HaversineCalculator.calculateBearing(
        lat1: AppConstants.defaultSpbnLatitude,
        lon1: AppConstants.defaultSpbnLongitude,
        lat2: -7.240000,
        lon2: 113.536000,
      );
      expect(bearing, inInclusiveRange(0.0, 360.0));
    });
  });

  group('LocationSecurityService Evaluation Tests', () {
    const service = LocationSecurityService();

    test('Detects mock location when position.isMocked is true', () {
      final mockPosition = Position(
        latitude: AppConstants.defaultSpbnLatitude,
        longitude: AppConstants.defaultSpbnLongitude,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: true, // Fake GPS aktif
      );

      final result = service.evaluatePosition(mockPosition);
      expect(result.status, equals(GeofenceValidationStatus.mockGpsDetected));
      expect(result.isMocked, isTrue);
      expect(result.message, equals('TERDETEKSI LOKASI PALSU (FAKE GPS)'));
      expect(result.canTakeQueue, isFalse);
    });

    test('Rejects reading when accuracy > 35.0 meters', () {
      final lowAccuracyPosition = Position(
        latitude: AppConstants.defaultSpbnLatitude,
        longitude: AppConstants.defaultSpbnLongitude,
        timestamp: DateTime.now(),
        accuracy: 45.0, // > 35m
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      final result = service.evaluatePosition(lowAccuracyPosition);
      expect(result.status, equals(GeofenceValidationStatus.accuracyTooLow));
      expect(result.accuracy, equals(45.0));
      expect(result.canTakeQueue, isFalse);
    });

    test('Validates inside geofence when distance <= 100 meters with valid GPS', () {
      // Offset by ~20 meters
      final validPosition = Position(
        latitude: AppConstants.defaultSpbnLatitude + 0.0001,
        longitude: AppConstants.defaultSpbnLongitude + 0.0001,
        timestamp: DateTime.now(),
        accuracy: 8.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      final result = service.evaluatePosition(validPosition);
      expect(result.status, equals(GeofenceValidationStatus.validInside));
      expect(result.isInsideGeofence, isTrue);
      expect(result.isMocked, isFalse);
      expect(result.distanceMeters, lessThanOrEqualTo(100.0));
      expect(result.canTakeQueue, isTrue);
    });

    test('Validates outside geofence when distance > 100 meters', () {
      // Offset by ~550 meters
      final outsidePosition = Position(
        latitude: AppConstants.defaultSpbnLatitude + 0.005,
        longitude: AppConstants.defaultSpbnLongitude,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        isMocked: false,
      );

      final result = service.evaluatePosition(outsidePosition);
      expect(result.status, equals(GeofenceValidationStatus.outsideGeofence));
      expect(result.isInsideGeofence, isFalse);
      expect(result.distanceMeters, greaterThan(100.0));
      expect(result.canTakeQueue, isFalse);
    });
  });
}
