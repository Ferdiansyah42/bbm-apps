import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/main.dart';

void main() {
  testWidgets('AntrianSolarApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AntrianSolarApp(),
      ),
    );

    // Verify main navigation items
    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Antrean'), findsOneWidget);
    expect(find.text('QR Kuota'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
