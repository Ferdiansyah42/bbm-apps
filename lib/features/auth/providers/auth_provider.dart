import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_account.dart';

class AuthState {
  final UserAccount? currentUser;
  final List<UserAccount> registeredAccounts;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    required this.registeredAccounts,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    UserAccount? currentUser,
    bool clearCurrentUser = false,
    List<UserAccount>? registeredAccounts,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      currentUser: clearCurrentUser ? null : (currentUser ?? this.currentUser),
      registeredAccounts: registeredAccounts ?? this.registeredAccounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const List<UserAccount> defaultAccounts = [
    UserAccount(
      id: 'admin_spbn',
      nama: 'Administrator SPBN Branta',
      email: 'admin@gmail.com',
      noHp: '081111222333',
      password: '123450',
      role: 'operator',
    ),
    UserAccount(
      id: 'nelayan_1',
      nama: "Moh. Syafi'i (Nelayan)",
      email: 'nelayan@gmail.com',
      noHp: '081234567890',
      password: '123450',
      role: 'nelayan',
      nomorRekomendasi: 'REK-DKP-2026-084',
      kapasitasMesin: 'Mesin 10 PK - Maks. 30 Liter',
    ),
    UserAccount(
      id: 'nelayan_syafii',
      nama: "Moh. Syafi'i",
      email: 'syafii.nelayan@gmail.com',
      noHp: '081234567891',
      password: '123450',
      role: 'nelayan',
      nomorRekomendasi: 'REK-DKP-2026-084',
      kapasitasMesin: 'Mesin 10 PK - Maks. 30 Liter',
    ),
  ];

  @override
  AuthState build() {
    // currentUser bernilai null saat aplikasi pertama kali dibuka sesuai spesifikasi
    return const AuthState(
      currentUser: null,
      registeredAccounts: defaultAccounts,
    );
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final cleanId = identifier.trim();
    final cleanPass = password.trim();

    if (cleanId.isEmpty || cleanPass.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email/No. HP dan Password wajib diisi.',
      );
      return false;
    }

    // Gabungkan defaultAccounts dengan state.registeredAccounts
    // agar akun baru langsung dikenali secara instan bahkan tanpa Hot Restart
    final Map<String, UserAccount> accountMap = {};
    for (final acc in defaultAccounts) {
      accountMap[acc.email.toLowerCase()] = acc;
    }
    for (final acc in state.registeredAccounts) {
      accountMap[acc.email.toLowerCase()] = acc;
    }

    final matched = accountMap.values.where((acc) {
      final idMatch = acc.email.toLowerCase() == cleanId.toLowerCase() ||
          acc.noHp == cleanId ||
          acc.id.toLowerCase() == cleanId.toLowerCase();
      // Cocokkan password (bisa 123450 maupun 123456 untuk kemudahan pengujian)
      final passMatch = acc.password == cleanPass ||
          cleanPass == '123450' ||
          cleanPass == '123456';
      return idMatch && passMatch;
    }).firstOrNull;

    if (matched == null) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email/No. HP atau Password salah. Silakan periksa kembali.',
      );
      return false;
    }

    state = state.copyWith(
      currentUser: matched,
      registeredAccounts: accountMap.values.toList(),
      isLoading: false,
      clearErrorMessage: true,
    );

    return true;
  }

  Future<bool> register(UserAccount newAccount) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    await Future.delayed(const Duration(milliseconds: 300));

    final exists = state.registeredAccounts.any(
      (acc) =>
          acc.email.toLowerCase() == newAccount.email.toLowerCase() ||
          acc.noHp == newAccount.noHp,
    );

    if (exists) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Email atau Nomor HP sudah terdaftar. Silakan login.',
      );
      return false;
    }

    final updatedList = List<UserAccount>.from(state.registeredAccounts)..add(newAccount);
    state = state.copyWith(
      currentUser: newAccount,
      registeredAccounts: updatedList,
      isLoading: false,
      clearErrorMessage: true,
    );

    return true;
  }

  void demoLoginNelayan() {
    final demo = state.registeredAccounts.firstWhere((acc) => acc.isNelayan);
    state = state.copyWith(
      currentUser: demo,
      clearErrorMessage: true,
    );
  }

  void simulateGoogleLoginNelayan() {
    demoLoginNelayan();
  }

  void demoLoginOperator() {
    final demo = state.registeredAccounts.firstWhere((acc) => acc.isOperator);
    state = state.copyWith(
      currentUser: demo,
      clearErrorMessage: true,
    );
  }

  void logout() {
    state = state.copyWith(clearCurrentUser: true, clearErrorMessage: true);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Alias kompatibilitas
final authProvider = authNotifierProvider;
