import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/features/quota_qr/presentation/digital_pass_screen.dart';
import 'package:antrian_solar/features/siantri_solar/models/siantri_models.dart';
import 'package:antrian_solar/features/siantri_solar/providers/siantri_provider.dart';

void main() {
  testWidgets('DigitalPassScreen displays friendly empty state when no active ticket', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DigitalPassScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Tiket Antrean Aktif'), findsOneWidget);
    expect(find.textContaining('Belum ada tiket aktif, silakan daftar di menu SiAntri'), findsOneWidget);
    expect(find.text('Daftar di Menu SiAntri'), findsOneWidget);
  });

  testWidgets('DigitalPassScreen displays active ticket details matching user input', (tester) async {
    final testTicket = SiAntriTicket(
      queueNumber: 'SLR-002',
      fishermanName: "Moh. Syafi'i",
      recommendationNumber: 'REK-DKP-2026-084',
      engineTier: kBoatEngineTiers[1], // Mesin 15 PK (45L)
      requestedLiters: 45.0,
      estimatedTime: DateTime(2026, 11, 16, 14, 25),
      qrData: 'SIANTRI-SPBN-MADURA:SLR-002:REK-DKP-2026-084:45',
      createdAt: DateTime(2026, 11, 16, 14, 0),
    );

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DigitalPassScreen(),
        ),
      ),
    );

    // Set active ticket in the container
    final element = tester.element(find.byType(DigitalPassScreen));
    final container = ProviderScope.containerOf(element);
    container.read(activeTicketProvider.notifier).setTicket(testTicket);

    await tester.pumpAndSettle();

    // Verify user inputted data is rendered
    expect(find.text('SLR-002'), findsOneWidget);
    expect(find.text("Moh. Syafi'i"), findsOneWidget);
    expect(find.text('REK-DKP-2026-084'), findsWidgets);
    expect(find.text('Mesin 15 PK'), findsOneWidget);
    expect(find.text('45 Liter'), findsOneWidget);
    expect(find.text('MENUNGGU'), findsOneWidget);
    expect(find.text('Perbesar QR'), findsOneWidget);
    expect(find.text('Batal Antre'), findsOneWidget);
  });
}
