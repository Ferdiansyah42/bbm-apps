import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/fisherman_user.dart';
import '../../../core/repositories/mock_spbn_repository.dart';

class AuthState {
  final bool isAuthenticated;
  final FishermanUser? user;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    required this.isAuthenticated,
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  factory AuthState.initial() => const AuthState(
        isAuthenticated: true, // Default true agar langsung bisa diuji coba saat aplikasi dibuka
      );

  AuthState copyWith({
    bool? isAuthenticated,
    FishermanUser? user,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => _loadUser());
    return AuthState.initial();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ref.read(fishermanProfileProvider.future);
      state = state.copyWith(user: user);
    } catch (_) {}
  }

  Future<bool> login(String identifier) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    await Future.delayed(const Duration(milliseconds: 600));

    final trimmed = identifier.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'NIK atau Nomor HP tidak boleh kosong.',
      );
      return false;
    }

    if (trimmed.length < 10) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Format NIK/No. HP tidak valid (minimal 10 digit).',
      );
      return false;
    }

    try {
      final user = await ref.read(fishermanProfileProvider.future);
      state = AuthState(
        isAuthenticated: true,
        user: user,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat profil: $e',
      );
      return false;
    }
  }

  void logout() {
    state = const AuthState(
      isAuthenticated: false,
      user: null,
      isLoading: false,
    );
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);
