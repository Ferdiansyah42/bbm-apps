import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController(text: '3528011204850001');
  final _passwordController = TextEditingController(text: '123456');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _identifierController.text.trim();
    final pass = _passwordController.text.trim();

    final success = await ref.read(authNotifierProvider.notifier).login(
          identifier: id,
          password: pass,
        );

    if (!mounted) return;

    if (!success) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Login gagal. Silakan periksa kembali.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _demoLoginNelayan() {
    ref.read(authNotifierProvider.notifier).demoLoginNelayan();
  }

  void _demoLoginOperator() {
    ref.read(authNotifierProvider.notifier).demoLoginOperator();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo & Header Maritim
                  Center(
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F2B48), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_boat_rounded,
                        size: 46,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'SiAntri Solar Nelayan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SPBN 54.693.01 Branta Pasian - Pamekasan Madura',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Login Card
                  Card(
                    elevation: 1,
                    shadowColor: AppColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    color: AppColors.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(22.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lock_person_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Masuk ke Sistem Antrean',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Input NIK atau No HP
                          TextFormField(
                            controller: _identifierController,
                            keyboardType: TextInputType.text,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            decoration: const InputDecoration(
                              labelText: 'NIK / Nomor Handphone / ID',
                              hintText: 'Contoh: 3528011204850001',
                              prefixIcon: Icon(Icons.badge_outlined, color: AppColors.primary),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'NIK atau Nomor HP wajib diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 14),

                          // Input Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            decoration: InputDecoration(
                              labelText: 'Kata Sandi / Password',
                              hintText: 'Masukkan kata sandi akun',
                              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: AppColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Password wajib diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Tombol Masuk Utama
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: authState.isLoading ? null : _handleLogin,
                              icon: authState.isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                    )
                                  : const Icon(Icons.login_rounded),
                              label: Text(
                                authState.isLoading ? 'Memverifikasi...' : 'Masuk',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Link Daftar Akun Nelayan
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                  );
                                },
                                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                                child: const Text(
                                  'Daftar Akun Nelayan',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Akses Cepat Pengujian (Demo Login)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFD97706)),
                            SizedBox(width: 4),
                            Text(
                              'Akses Cepat Pengujian (1-Klik Masuk):',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _demoLoginNelayan,
                                icon: const Icon(Icons.directions_boat_rounded, size: 16),
                                label: const Text('Demo Nelayan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _demoLoginOperator,
                                icon: const Icon(Icons.badge_rounded, size: 16),
                                label: const Text('Demo Operator', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFD97706),
                                  side: const BorderSide(color: Color(0xFFD97706)),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
