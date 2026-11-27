import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/core/repositories/mock_spbn_repository.dart';
import 'package:antrian_solar/main.dart';

void main() {
  testWidgets('AntrianSolarApp shows LoginScreen initially and navigates on demo login', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spbnRepositoryProvider.overrideWith((ref) => MockSpbnRepository()),
        ],
        child: const AntrianSolarApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify LoginScreen is shown initially
    expect(find.text('SiAntri Solar Nelayan'), findsOneWidget);
    expect(find.text('Masuk ke Sistem Antrean'), findsOneWidget);
    expect(find.text('Demo Nelayan'), findsOneWidget);

    // Scroll if needed and tap "Demo Nelayan" button to log in
    await tester.ensureVisible(find.text('Demo Nelayan'));
    await tester.tap(find.text('Demo Nelayan'));
    await tester.pumpAndSettle();

    // Verify main navigation items appear after login
    expect(find.text('SiAntri'), findsOneWidget);
    expect(find.text('Radar SPBU'), findsOneWidget);
    expect(find.text('Prioritas'), findsOneWidget);
    expect(find.text('Pas QR'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });

  testWidgets('All tabs render on narrow mobile screen (360x800) without any RenderFlex overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spbnRepositoryProvider.overrideWith((ref) => MockSpbnRepository()),
        ],
        child: const AntrianSolarApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Login via demo
    await tester.ensureVisible(find.text('Demo Nelayan'));
    await tester.tap(find.text('Demo Nelayan'));
    await tester.pumpAndSettle();

    // Tab 0: SiAntri
    expect(tester.takeException(), isNull);

    // Tab 1: Radar SPBU (HomeDashboardScreen)
    await tester.tap(find.text('Radar SPBU'));
    await tester.pumpAndSettle();
    expect(find.text('Radar Geofencing GPS'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tab 2: Prioritas (QueueScreen)
    await tester.tap(find.text('Prioritas'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Tab 3: Pas QR (DigitalPassScreen)
    await tester.tap(find.text('Pas QR'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Tab 4: Riwayat (HistoryScreen)
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
