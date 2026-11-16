import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/core/constants/app_constants.dart';
import 'package:antrian_solar/core/models/models.dart';
import 'package:antrian_solar/core/repositories/mock_spbn_repository.dart';

void main() {
  group('Data Models Tests (Serialization & Blueprint Rules)', () {
    test('FishermanUser fromJson & toJson with small tier weight', () {
      final user = FishermanUser(
        id: 1,
        name: 'Achmad Zaini',
        nik: '3528011204850002',
        phone: '081234567890',
        fishermanTier: 'small',
      );

      final json = user.toJson();
      expect(json['nik'], equals('3528011204850002'));
      expect(user.isSmallFisherman, isTrue);
      expect(user.categoryWeight, equals(1.0));

      final deserialized = FishermanUser.fromJson(json);
      expect(deserialized.name, equals('Achmad Zaini'));
      expect(deserialized.categoryWeight, equals(1.0));
    });

    test('Ship model serialization for KM Mina Jaya 15 PK', () {
      final ship = Ship(
        id: 1,
        userId: 1,
        shipName: 'KM Mina Jaya',
        gtSize: 3.0,
        enginePk: 15.0,
        dailyNeedEst: 35.0,
      );

      final json = ship.toJson();
      expect(json['ship_name'], equals('KM Mina Jaya'));
      expect(json['engine_pk'], equals(15.0));

      final deserialized = Ship.fromJson(json);
      expect(deserialized.shipName, equals('KM Mina Jaya'));
      expect(deserialized.enginePk, equals(15.0));
      expect(deserialized.gtSize, equals(3.0));
    });

    test('RecommendationLetter calculations (quota 450L, remaining 270L)', () {
      final letter = RecommendationLetter(
        id: 1,
        shipId: 1,
        barcodeNumber: 'REK-DKP-2026-MADURA-001',
        allocatedQuota: 450.0,
        remainingQuota: 270.0,
        validFrom: DateTime.now().subtract(const Duration(days: 10)),
        validUntil: DateTime.now().add(const Duration(days: 80)),
      );

      expect(letter.quotaUsed, equals(180.0));
      expect(letter.remainingRatio, closeTo(0.6, 0.001));
      expect(letter.usedPercentage, closeTo(40.0, 0.001));
      expect(letter.isQuotaAvailable, isTrue);
      expect(letter.isExpired, isFalse);

      final json = letter.toJson();
      final deserialized = RecommendationLetter.fromJson(json);
      expect(deserialized.barcodeNumber, equals('REK-DKP-2026-MADURA-001'));
      expect(deserialized.remainingQuota, equals(270.0));
    });

    test('TransactionHistory handles anomaly flags and explanation reasons', () {
      final tx = TransactionHistory(
        id: 98,
        spbnId: 1,
        shipId: 1,
        letterId: 1,
        transactionRef: 'TRX-20261106-0092',
        volumeLiters: 70.0,
        anomalyScore: 0.86,
        isAnomaly: true,
        anomalyReasons: const ['Frekuensi pembelian tinggi: 3 transaksi dalam 24 jam terakhir.'],
        createdAt: DateTime.now(),
      );

      final json = tx.toJson();
      expect(json['is_anomaly'], isTrue);
      expect(json['anomaly_score'], equals(0.86));

      final deserialized = TransactionHistory.fromJson(json);
      expect(deserialized.isAnomaly, isTrue);
      expect(deserialized.anomalyReasons.length, equals(1));
    });
  });

  group('MockSpbnRepository Tests (SPBN Madura Simulation)', () {
    late MockSpbnRepository repository;

    setUp(() {
      repository = MockSpbnRepository();
    });

    test('Retrieve default mock profile, ship, and recommendation letter', () async {
      final user = await repository.getFishermanProfile();
      expect(user.nik, equals('3528011204850002'));

      final ship = await repository.getActiveShip();
      expect(ship.shipName, equals('KM Mina Jaya'));
      expect(ship.enginePk, equals(15.0));

      final letter = await repository.getRecommendationLetter();
      expect(letter.allocatedQuota, equals(450.0));
      expect(letter.remainingQuota, equals(270.0));
    });

    test('takePriorityQueue throws MockLocationDetectedException when isMocked is true', () async {
      await expectLater(
        repository.takePriorityQueue(
          userLat: AppConstants.defaultSpbnLatitude,
          userLon: AppConstants.defaultSpbnLongitude,
          isMocked: true,
          accuracy: 10.0,
        ),
        throwsA(isA<MockLocationDetectedException>()),
      );
    });

    test('takePriorityQueue throws GpsAccuracyTooLowException when accuracy > 35m', () async {
      await expectLater(
        repository.takePriorityQueue(
          userLat: AppConstants.defaultSpbnLatitude,
          userLon: AppConstants.defaultSpbnLongitude,
          isMocked: false,
          accuracy: 45.0,
        ),
        throwsA(isA<GpsAccuracyTooLowException>()),
      );
    });

    test('takePriorityQueue throws OutsideGeofenceException when > 100m from SPBN', () async {
      await expectLater(
        repository.takePriorityQueue(
          userLat: AppConstants.defaultSpbnLatitude + 0.005, // ~550m away
          userLon: AppConstants.defaultSpbnLongitude,
          isMocked: false,
          accuracy: 10.0,
        ),
        throwsA(isA<OutsideGeofenceException>()),
      );
    });

    test('takePriorityQueue succeeds inside geofence and calculates priority score correctly', () async {
      final ticket = await repository.takePriorityQueue(
        userLat: AppConstants.defaultSpbnLatitude,
        userLon: AppConstants.defaultSpbnLongitude,
        isMocked: false,
        accuracy: 10.0,
      );

      expect(ticket.queueCode, equals('P1-004'));
      // Sp = 0.6 * 1.0 + 0.4 * (270 / 450) = 0.6 + 0.24 = 0.84
      expect(ticket.priorityScore, closeTo(0.84, 0.01));
      expect(ticket.isWaiting, isTrue);

      // Attempting to take another queue while waiting throws ActiveQueueExistsException
      await expectLater(
        repository.takePriorityQueue(
          userLat: AppConstants.defaultSpbnLatitude,
          userLon: AppConstants.defaultSpbnLongitude,
          isMocked: false,
          accuracy: 10.0,
        ),
        throwsA(isA<ActiveQueueExistsException>()),
      );

      // Cancelling queue sets status to CANCELLED
      await repository.cancelQueue(ticket.id);
      final active = await repository.getActiveQueue();
      expect(active?.isCancelled, isTrue);
    });
  });
}
