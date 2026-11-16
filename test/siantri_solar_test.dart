import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/features/settings/models/spbn_settings.dart';
import 'package:antrian_solar/features/settings/providers/settings_provider.dart';
import 'package:antrian_solar/features/siantri_solar/models/siantri_models.dart';
import 'package:antrian_solar/features/siantri_solar/providers/siantri_provider.dart';

void main() {
  group('SiAntri Solar Nelayan Model & Config Tests', () {
    test('kBoatEngineTiers define correct maximum quota limits', () {
      final pk10 = kBoatEngineTiers.firstWhere((v) => v.id == 'pk_10');
      final pk15 = kBoatEngineTiers.firstWhere((v) => v.id == 'pk_15');
      final pk24 = kBoatEngineTiers.firstWhere((v) => v.id == 'pk_24');
      final pk30 = kBoatEngineTiers.firstWhere((v) => v.id == 'pk_30');

      expect(pk10.maxQuotaLiters, equals(30.0));
      expect(pk15.maxQuotaLiters, equals(45.0));
      expect(pk24.maxQuotaLiters, equals(60.0));
      expect(pk30.maxQuotaLiters, equals(80.0));
    });

    test('SiAntriTicket generates valid Boarding Pass QR Code payload', () {
      final ticket = SiAntriTicket(
        queueNumber: 'SLR-002',
        fishermanName: "Moh. Syafi'i",
        recommendationNumber: 'REK-DKP-2026-084',
        engineTier: kBoatEngineTiers[1], // Mesin 15 PK (45L)
        requestedLiters: 45.0,
        estimatedTime: DateTime(2026, 11, 16, 14, 30),
        qrData: 'SIANTRI-SPBN-MADURA:SLR-002:REK-DKP-2026-084:45',
        createdAt: DateTime(2026, 11, 16, 14, 0),
      );

      final payload = ticket.toQrPayload();
      expect(payload['queue_code'], equals('SLR-002'));
      expect(payload['fisherman_name'], equals("Moh. Syafi'i"));
      expect(payload['recommendation_number'], equals('REK-DKP-2026-084'));
      expect(payload['engine_capacity'], equals('Mesin 15 PK'));
      expect(payload['requested_liters'], equals(45.0));
      expect(ticket.encodeQr(), contains('SLR-002'));
    });
  });

  group('SiAntriNotifier State & Geofencing Mode Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state provides 4.250 L / 8.000 L stock and active FIFO queue', () {
      final state = container.read(siAntriProvider);

      expect(state.tankStockLiters, equals(4250.0));
      expect(state.tankCapacityLiters, equals(8000.0));
      expect(state.isAvailable, isTrue);
      expect(state.liveQueues.length, equals(1));
      expect(state.liveQueues.first.queueNumber, equals('SLR-001'));
      expect(state.liveQueues.first.status, equals('SERVING'));
      expect(state.currentTicket, isNull);
    });

    test('Mode Bebas Uji (isGeofenceEnabled == false) permits registration from anywhere', () {
      final state = container.read(siAntriProvider);
      const settings = SpbnSettings(isGeofenceEnabled: false);

      expect(state.canRegister(settings), isTrue);
    });

    test('Geofencing ON enforces GPS radius and blocks Fake GPS', () {
      final notifier = container.read(siAntriProvider.notifier);
      const settings = SpbnSettings(isGeofenceEnabled: true, radiusMeters: 100.0);

      // 1. Di dalam radius (35m) -> boleh daftar
      notifier.setGeofenceStatus(isInside: true, distance: 35.0, isMock: false);
      expect(container.read(siAntriProvider).canRegister(settings), isTrue);

      // 2. Di luar radius (350m) -> diblokir
      notifier.setGeofenceStatus(isInside: false, distance: 350.0, isMock: false);
      expect(container.read(siAntriProvider).canRegister(settings), isFalse);

      // 3. Terdeteksi Fake GPS -> diblokir
      notifier.setGeofenceStatus(isInside: true, distance: 20.0, isMock: true);
      expect(container.read(siAntriProvider).canRegister(settings), isFalse);
    });

    test('registerQueue generates SLR-002, updates tank stock, and appends to live queue', () {
      final notifier = container.read(siAntriProvider.notifier);
      final ticket = notifier.registerQueue(
        fishermanName: "Moh. Syafi'i",
        recommendationNumber: 'REK-DKP-2026-084',
        engineTier: kBoatEngineTiers[1], // 15 PK
        requestedLiters: 45.0,
      );

      expect(ticket.queueNumber, equals('SLR-002'));
      expect(ticket.fishermanName, equals("Moh. Syafi'i"));
      expect(ticket.recommendationNumber, equals('REK-DKP-2026-084'));
      expect(ticket.requestedLiters, equals(45.0));

      final state = container.read(siAntriProvider);
      expect(state.currentTicket, isNotNull);
      expect(state.currentTicket?.queueNumber, equals('SLR-002'));
      expect(state.liveQueues.length, equals(2));
      expect(state.liveQueues.last.queueNumber, equals('SLR-002'));
      expect(state.liveQueues.last.fishermanName, equals("Moh. Syafi'i"));
      expect(state.tankStockLiters, equals(4250.0 - 45.0));
    });

    test('cancelTicket clears active ticket and removes it from live queue', () {
      final notifier = container.read(siAntriProvider.notifier);
      notifier.registerQueue(
        fishermanName: 'Pak Badri',
        recommendationNumber: 'REK-DKP-2026-099',
        engineTier: kBoatEngineTiers[0],
        requestedLiters: 30.0,
      );

      expect(container.read(siAntriProvider).currentTicket, isNotNull);

      notifier.cancelTicket();
      final state = container.read(siAntriProvider);
      expect(state.currentTicket, isNull);
      expect(state.liveQueues.any((q) => q.recommendationNumber == 'REK-DKP-2026-099'), isFalse);
    });
  });

  group('SpbnSettings and SettingsNotifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Default SpbnSettings has isGeofenceEnabled == false', () {
      final settings = container.read(settingsProvider);
      expect(settings.isGeofenceEnabled, isFalse);
      expect(settings.latitude, equals(-7.239400));
      expect(settings.longitude, equals(113.535600));
      expect(settings.radiusMeters, equals(100.0));
    });

    test('setGeofenceEnabled updates isGeofenceEnabled state', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setGeofenceEnabled(true);

      expect(container.read(settingsProvider).isGeofenceEnabled, isTrue);

      await notifier.setGeofenceEnabled(false);
      expect(container.read(settingsProvider).isGeofenceEnabled, isFalse);
    });

    test('updateSettings updates coordinates and radius', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.updateSettings(
        latitude: -7.195200,
        longitude: 113.334100,
        radiusMeters: 150.0,
        spbnName: 'SPBN Camplong Sampang',
      );

      final state = container.read(settingsProvider);
      expect(state.latitude, equals(-7.195200));
      expect(state.longitude, equals(113.334100));
      expect(state.radiusMeters, equals(150.0));
      expect(state.spbnName, equals('SPBN Camplong Sampang'));
    });

    test('resetToDefault restores default coordinates and disables geofence', () async {
      final notifier = container.read(settingsProvider.notifier);
      await notifier.setGeofenceEnabled(true);
      await notifier.updateSettings(
        latitude: -7.999999,
        longitude: 113.999999,
        radiusMeters: 500.0,
        spbnName: 'Custom SPBN',
      );

      await notifier.resetToDefault();
      final state = container.read(settingsProvider);
      expect(state.isGeofenceEnabled, isFalse);
      expect(state.latitude, equals(-7.239400));
      expect(state.longitude, equals(113.535600));
      expect(state.radiusMeters, equals(100.0));
    });
  });
}
