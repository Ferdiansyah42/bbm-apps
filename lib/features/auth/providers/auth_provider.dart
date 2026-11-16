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
      id: 'nelayan_1',
      nama: "Moh. Syafi'i",
      email: 'syafii.nelayan@gmail.com',
      noHp: '081234567890',
      password: '123456',
      role: 'nelayan',
      nomorRekomendasi: 'REK-DKP-2026-084',
      kapasitasMesin: 'Mesin 10 PK - Maks. 30 Liter',
    ),
    UserAccount(
      id: 'admin_spbn',
      nama: 'Petugas SPBN Branta',
      email: 'operator.spbn@gmail.com',
      noHp: '081111222333',
      password: '123456',
      role: 'operator',
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

    final matched = state.registeredAccounts.where((acc) {
      final idMatch = acc.email.toLowerCase() == cleanId.toLowerCase() ||
          acc.noHp == cleanId ||
          acc.id == cleanId;
      return idMatch && acc.password == cleanPass;
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
