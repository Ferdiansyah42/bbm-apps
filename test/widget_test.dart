import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/core/repositories/mock_spbn_repository.dart';
import 'package:antrian_solar/main.dart';

void main() {
  testWidgets('AntrianSolarApp basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          spbnRepositoryProvider.overrideWith((ref) => MockSpbnRepository()),
        ],
        child: const AntrianSolarApp(),
      ),
    );

    // Tunggu semua Future/Timer async selesai diproses
    await tester.pumpAndSettle();

    // Verify main navigation items
    expect(find.text('SiAntri'), findsOneWidget);
    expect(find.text('Radar SPBU'), findsOneWidget);
    expect(find.text('Prioritas'), findsOneWidget);
    expect(find.text('Pas QR'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
  });
}
