import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/features/auth/models/user_account.dart';
import 'package:antrian_solar/features/auth/presentation/login_screen.dart';
import 'package:antrian_solar/features/auth/presentation/register_screen.dart';
import 'package:antrian_solar/features/auth/providers/auth_provider.dart';

void main() {
  group('UserAccount & AuthNotifier State Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial AuthState has null currentUser and default dummy accounts', () {
      final state = container.read(authNotifierProvider);

      expect(state.currentUser, isNull);
      expect(state.isAuthenticated, isFalse);
      expect(state.registeredAccounts.length, equals(2));

      // Verify Nelayan account
      final nelayan = state.registeredAccounts.firstWhere((a) => a.isNelayan);
      expect(nelayan.nik, equals('3528011204850001'));
      expect(nelayan.noHp, equals('081234567890'));
      expect(nelayan.password, equals('123456'));
      expect(nelayan.nama, equals("Moh. Syafi'i"));
      expect(nelayan.nomorRekomendasi, equals('REK-DKP-2026-084'));
      expect(nelayan.kapasitasMesin, equals('Mesin 10 PK - Maks. 30 Liter'));

      // Verify Operator account
      final operator = state.registeredAccounts.firstWhere((a) => a.isOperator);
      expect(operator.nik, equals('admin_spbn'));
      expect(operator.nama, equals('Petugas SPBN Branta'));
      expect(operator.password, equals('123456'));
      expect(operator.role, equals('operator'));
    });

    test('login validates credentials and handles errors', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      // 1. Empty credentials
      var ok = await notifier.login(identifier: '', password: '');
      expect(ok, isFalse);
      expect(container.read(authNotifierProvider).errorMessage, contains('wajib diisi'));

      // 2. Wrong password
      ok = await notifier.login(identifier: '3528011204850001', password: 'wrongpassword');
      expect(ok, isFalse);
      expect(container.read(authNotifierProvider).errorMessage, contains('salah'));

      // 3. Login by NIK
      ok = await notifier.login(identifier: '3528011204850001', password: '123456');
      expect(ok, isTrue);
      expect(container.read(authNotifierProvider).currentUser?.nama, equals("Moh. Syafi'i"));

      // 4. Logout
      notifier.logout();
      expect(container.read(authNotifierProvider).currentUser, isNull);

      // 5. Login by No HP
      ok = await notifier.login(identifier: '081234567890', password: '123456');
      expect(ok, isTrue);
      expect(container.read(authNotifierProvider).currentUser?.nama, equals("Moh. Syafi'i"));

      // 6. Login Operator by ID
      notifier.logout();
      ok = await notifier.login(identifier: 'admin_spbn', password: '123456');
      expect(ok, isTrue);
      expect(container.read(authNotifierProvider).currentUser?.isOperator, isTrue);
    });

    test('register adds new fisherman account and sets currentUser', () async {
      final notifier = container.read(authNotifierProvider.notifier);

      const newAccount = UserAccount(
        id: 'nelayan_2',
        nama: 'Pak Badri',
        nik: '3528011204850099',
        noHp: '081987654321',
        password: 'password123',
        role: 'nelayan',
        nomorRekomendasi: 'REK-DKP-2026-099',
        kapasitasMesin: 'Mesin 15 PK - Maks. 45 Liter',
      );

      final ok = await notifier.register(newAccount);
      expect(ok, isTrue);

      final state = container.read(authNotifierProvider);
      expect(state.currentUser?.nama, equals('Pak Badri'));
      expect(state.currentUser?.nomorRekomendasi, equals('REK-DKP-2026-099'));
      expect(state.registeredAccounts.length, equals(3));

      // Duplicate registration rejected
      final duplicateOk = await notifier.register(newAccount);
      expect(duplicateOk, isFalse);
      expect(container.read(authNotifierProvider).errorMessage, contains('sudah terdaftar'));
    });

    test('demoLoginNelayan and demoLoginOperator log in instantly', () {
      final notifier = container.read(authNotifierProvider.notifier);

      notifier.demoLoginNelayan();
      expect(container.read(authNotifierProvider).currentUser?.isNelayan, isTrue);
      expect(container.read(authNotifierProvider).currentUser?.nama, equals("Moh. Syafi'i"));

      notifier.demoLoginOperator();
      expect(container.read(authNotifierProvider).currentUser?.isOperator, isTrue);
      expect(container.read(authNotifierProvider).currentUser?.nama, equals('Petugas SPBN Branta'));
    });
  });

  group('LoginScreen and RegisterScreen UI Tests', () {
    testWidgets('LoginScreen renders form inputs and demo login buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SiAntri Solar Nelayan'), findsOneWidget);
      expect(find.text('Masuk ke Sistem Antrean'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
      expect(find.text('Daftar Akun Nelayan'), findsOneWidget);
      expect(find.text('Demo Nelayan'), findsOneWidget);
      expect(find.text('Demo Operator'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders registration form and dropdown', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Daftar Akun Nelayan'), findsOneWidget);
      expect(find.text('Nama Lengkap Nelayan'), findsOneWidget);
      expect(find.text('Nomor Induk Kependudukan (NIK)'), findsOneWidget);
      expect(find.text('Nomor Handphone / WhatsApp'), findsOneWidget);
      expect(find.text('Nomor Surat Rekomendasi DKP'), findsOneWidget);
      expect(find.text('Daftar & Masuk'), findsOneWidget);
    });
  });
}
