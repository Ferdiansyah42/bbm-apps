import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/features/operator/presentation/operator_panel_screen.dart';
import 'package:antrian_solar/features/siantri_solar/models/siantri_models.dart';
import 'package:antrian_solar/features/siantri_solar/providers/siantri_provider.dart';

void main() {
  group('AppRoleNotifier & Operator State Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('appRoleProvider defaults to fisherman and can switch to operator', () {
      expect(container.read(appRoleProvider), equals(UserRole.fisherman));

      container.read(appRoleProvider.notifier).setRole(UserRole.operator);
      expect(container.read(appRoleProvider), equals(UserRole.operator));

      container.read(appRoleProvider.notifier).toggleRole();
      expect(container.read(appRoleProvider), equals(UserRole.fisherman));
    });

    test('completeCurrentServing records completed transaction and advances queue', () {
      final notifier = container.read(siAntriProvider.notifier);

      // Register second queue
      notifier.registerQueue(
        fishermanName: "Moh. Syafi'i",
        recommendationNumber: 'REK-DKP-2026-084',
        engineTier: kBoatEngineTiers[1], // 45L
        requestedLiters: 45.0,
      );

      final stateBefore = container.read(siAntriProvider);
      expect(stateBefore.currentServingQueue?.queueNumber, equals('SLR-001'));
      expect(stateBefore.waitingQueueCount, equals(1)); // SLR-002

      // Operator completes SLR-001
      final tx = notifier.completeCurrentServing();
      expect(tx, isNotNull);
      expect(tx?.queueNumber, equals('SLR-001'));
      expect(tx?.fishermanName, equals('Pak Achmad Zaini'));

      final stateAfter = container.read(siAntriProvider);
      // SLR-002 is now promoted to SERVING
      expect(stateAfter.currentServingQueue?.queueNumber, equals('SLR-002'));
      expect(stateAfter.completedTransactions.first.queueNumber, equals('SLR-001'));
      expect(stateAfter.totalLitersDispensedToday, greaterThanOrEqualTo(105.0)); // 60 + 45
    });

    test('skipCurrentServing removes current ticket and promotes next', () {
      final notifier = container.read(siAntriProvider.notifier);

      notifier.registerQueue(
        fishermanName: 'Pak Badri',
        recommendationNumber: 'REK-DKP-2026-099',
        engineTier: kBoatEngineTiers[0],
        requestedLiters: 30.0,
      );

      final skipped = notifier.skipCurrentServing();
      expect(skipped?.queueNumber, equals('SLR-001'));

      final state = container.read(siAntriProvider);
      expect(state.currentServingQueue?.queueNumber, equals('SLR-002'));
    });

    test('setSolarStatus updates availability and state', () {
      final notifier = container.read(siAntriProvider.notifier);

      notifier.setSolarStatus(SolarAvailabilityStatus.runningLow);
      expect(container.read(siAntriProvider).solarStatus, equals(SolarAvailabilityStatus.runningLow));
      expect(container.read(siAntriProvider).isAvailable, isTrue);

      notifier.setSolarStatus(SolarAvailabilityStatus.empty);
      expect(container.read(siAntriProvider).solarStatus, equals(SolarAvailabilityStatus.empty));
      expect(container.read(siAntriProvider).isAvailable, isFalse);
    });

    test('addTankStock increments tank stock volume up to capacity', () {
      final notifier = container.read(siAntriProvider.notifier);

      notifier.addTankStock(4000.0);
      final newStock = container.read(siAntriProvider).tankStockLiters;
      expect(newStock, equals(8000.0)); // 4250 + 4000 clamped to 8000 max capacity
    });
  });

  group('OperatorPanelScreen Widget Tests', () {
    testWidgets('OperatorPanelScreen renders all operator cards and elements', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: OperatorPanelScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Panel Operator SPBN'), findsOneWidget);
      expect(find.text('Kontrol Dispenser — Sedang Dilayani'), findsOneWidget);
      expect(find.text('Verifikasi Cepat Tiket / QR Code'), findsOneWidget);
      expect(find.text('Manajemen Status & Saldo Tangki SPBN'), findsOneWidget);
      expect(find.text('Riwayat Pengisian Selesai Hari Ini'), findsOneWidget);
      expect(find.text('Verifikasi & Selesaikan'), findsOneWidget);
      expect(find.text('Lewati'), findsOneWidget);
      expect(find.text('+ Tambah Stok / Bongkar Tangki (+4.000 Liter)'), findsOneWidget);
    });
  });
}
