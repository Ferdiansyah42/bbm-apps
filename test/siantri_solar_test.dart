import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/features/siantri_solar/models/siantri_models.dart';
import 'package:antrian_solar/features/siantri_solar/providers/siantri_provider.dart';

void main() {
  group('SiAntri Solar Model & Config Tests', () {
    test('VehicleTypeConfigs define correct maximum quota limits', () {
      final r4Pribadi = kVehicleTypes.firstWhere((v) => v.id == 'r4_pribadi');
      final r4Angkutan = kVehicleTypes.firstWhere((v) => v.id == 'r4_angkutan');
      final trukR6 = kVehicleTypes.firstWhere((v) => v.id == 'truk_r6');
      final busBesar = kVehicleTypes.firstWhere((v) => v.id == 'bus_besar');

      expect(r4Pribadi.maxQuotaLiters, equals(40.0));
      expect(r4Angkutan.maxQuotaLiters, equals(60.0));
      expect(trukR6.maxQuotaLiters, equals(80.0));
      expect(busBesar.maxQuotaLiters, equals(100.0));
    });

    test('SiAntriTicket generates valid QR Code payload', () {
      final ticket = SiAntriTicket(
        queueNumber: 'SLR-004',
        driverName: 'Pak Wahid',
        plateNumber: 'M 4582 BG',
        vehicleType: kVehicleTypes[2], // Truk R6 (80L)
        requestedLiters: 80.0,
        estimatedTime: DateTime(2026, 11, 16, 10, 30),
        qrData: 'SIANTRI-SPBU-MADURA:SLR-004:M 4582 BG:80',
        createdAt: DateTime(2026, 11, 16, 10, 0),
      );

      final payload = ticket.toQrPayload();
      expect(payload['queue_code'], equals('SLR-004'));
      expect(payload['plate'], equals('M 4582 BG'));
      expect(payload['liters'], equals(80.0));
      expect(ticket.encodeQr(), contains('SLR-004'));
    });
  });

  group('SiAntriNotifier State Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state provides realistic SPBU stock and active FIFO queue', () {
      final state = container.read(siAntriProvider);

      expect(state.tankStockLiters, equals(14250.0));
      expect(state.isAvailable, isTrue);
      expect(state.isInsideGeofence, isTrue);
      expect(state.liveQueues.length, equals(3));
      expect(state.liveQueues.first.status, equals('SERVING'));
      expect(state.currentTicket, isNull);
    });

    test('registerQueue generates SLR-004 and adds to live FIFO queue', () {
      final notifier = container.read(siAntriProvider.notifier);
      final ticket = notifier.registerQueue(
        driverName: 'H. Abdul Wahid',
        plateNumber: 'M 4582 BG',
        vehicleType: kVehicleTypes[2], // Truk R6
        requestedLiters: 80.0,
      );

      expect(ticket.queueNumber, equals('SLR-004'));
      expect(ticket.plateNumber, equals('M 4582 BG'));
      expect(ticket.requestedLiters, equals(80.0));

      final state = container.read(siAntriProvider);
      expect(state.currentTicket, isNotNull);
      expect(state.currentTicket?.queueNumber, equals('SLR-004'));
      expect(state.liveQueues.length, equals(4));
      expect(state.liveQueues.last.queueNumber, equals('SLR-004'));
      expect(state.liveQueues.last.driverName, equals('H. Abdul Wahid'));
      expect(state.tankStockLiters, equals(14250.0 - 80.0));
    });

    test('cancelTicket removes ticket and live queue item', () {
      final notifier = container.read(siAntriProvider.notifier);
      notifier.registerQueue(
        driverName: 'Pak Syamsudin',
        plateNumber: 'M 7789 CD',
        vehicleType: kVehicleTypes[0],
        requestedLiters: 40.0,
      );

      expect(container.read(siAntriProvider).currentTicket, isNotNull);

      notifier.cancelTicket();
      final state = container.read(siAntriProvider);
      expect(state.currentTicket, isNull);
      expect(state.liveQueues.any((q) => q.plateNumber == 'M 7789 CD'), isFalse);
    });

    test('setGeofenceStatus toggles geofence state', () {
      final notifier = container.read(siAntriProvider.notifier);

      notifier.setGeofenceStatus(false, 350.0);
      expect(container.read(siAntriProvider).isInsideGeofence, isFalse);
      expect(container.read(siAntriProvider).currentDistanceMeters, equals(350.0));

      notifier.setGeofenceStatus(true, 15.0);
      expect(container.read(siAntriProvider).isInsideGeofence, isTrue);
      expect(container.read(siAntriProvider).currentDistanceMeters, equals(15.0));
    });
  });
}
