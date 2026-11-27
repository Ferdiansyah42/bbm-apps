import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../siantri_solar/models/siantri_models.dart';
import '../models/user_account.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _rekomendasiController = TextEditingController(
    text: 'REK-DKP-2026-099',
  );
  final _passwordController = TextEditingController();

  BoatEngineTier _selectedEngine = kBoatEngineTiers[1]; // Default 15 PK (45 L)
  bool _obscurePassword = true;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _rekomendasiController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final nama = _namaController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final noHp = _noHpController.text.trim();
    final rekomendasi = _rekomendasiController.text.trim().toUpperCase();
    final password = _passwordController.text.trim();

    final newAccount = UserAccount(
      id: 'nelayan_${DateTime.now().millisecondsSinceEpoch}',
      nama: nama,
      email: email,
      noHp: noHp,
      password: password,
      role: 'nelayan',
      nomorRekomendasi: rekomendasi,
      kapasitasMesin: _selectedEngine.label,
    );

    final success = await ref
        .read(authNotifierProvider.notifier)
        .register(newAccount);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran berhasil! Selamat datang, $nama'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      final error =
          ref.read(authNotifierProvider).errorMessage ?? 'Pendaftaran gagal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // BAGIAN ATAS: FORM REGISTRASI
            // ==========================================
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                left: 26.0,
                right: 26.0,
                bottom: 24.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title Registration
                    const Center(
                      child: Text(
                        'Registration',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F2B48),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Center(
                      child: Text(
                        'Daftar Akun Nelayan',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 1. Input Nama Lengkap Nelayan
                    _buildCapsuleInput(
                      controller: _namaController,
                      hintText: "Contoh: Moh. Syafi'i",
                      labelText: 'Nama Lengkap Nelayan',
                      icon: Icons.person_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nama lengkap nelayan wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // 2. Input Alamat Email / Gmail
                    _buildCapsuleInput(
                      controller: _emailController,
                      hintText: 'syafii.nelayan@gmail.com',
                      labelText: 'Alamat Email / Gmail',
                      icon: Icons.mail_rounded,
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Alamat Email / Gmail wajib diisi';
                        }
                        if (!val.contains('@')) {
                          return 'Format email harus valid (mengandung @)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // 3. Input Nomor Handphone / WhatsApp
                    _buildCapsuleInput(
                      controller: _noHpController,
                      hintText: 'Contoh: 081234567890',
                      labelText: 'Nomor Handphone / WhatsApp',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor Handphone / WhatsApp wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // 4. Input Nomor Surat Rekomendasi DKP
                    _buildCapsuleInput(
                      controller: _rekomendasiController,
                      hintText: 'REK-DKP-2026-099',
                      labelText: 'Nomor Surat Rekomendasi DKP',
                      icon: Icons.assignment_rounded,
                      textCapitalization: TextCapitalization.characters,
                      suffixAction: IconButton(
                        icon: const Icon(
                          Icons.auto_fix_high_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        tooltip: 'Gunakan nomor rekomendasi otomatis',
                        onPressed: () {
                          _rekomendasiController.text = 'REK-DKP-2026-099';
                        },
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Nomor surat rekomendasi DKP wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    // 5. Dropdown Kapasitas Mesin Kapal & Kuota
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonFormField<BoatEngineTier>(
                        key: ValueKey(_selectedEngine.id),
                        initialValue: _selectedEngine,
                        decoration: const InputDecoration(
                          labelText: 'Kapasitas Mesin Kapal & Kuota',
                          labelStyle: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.directions_boat_rounded,
                            color: Color(0xFF334155),
                            size: 22,
                          ),
                        ),
                        items: kBoatEngineTiers.map((tier) {
                          return DropdownMenuItem<BoatEngineTier>(
                            value: tier,
                            child: Text(
                              tier.label,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (tier) {
                          if (tier != null) {
                            setState(() => _selectedEngine = tier);
                          }
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 6. Input Password
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF0F2B48),
                        ),
                        decoration: InputDecoration(
                          hintText: 'Password',
                          labelText: 'Kata Sandi / Password',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13.5,
                          ),
                          labelStyle: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              color: const Color(0xFF334155),
                              size: 22,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Password wajib diisi';
                          }
                          if (val.length < 6) {
                            return 'Password minimal 6 karakter';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 7. Tombol Utama Register
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F2B48),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: authState.isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          authState.isLoading
                              ? 'Mendaftarkan...'
                              : 'Daftar & Masuk',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15.5,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Tombol Daftar dengan Google
                    SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(authNotifierProvider.notifier)
                              .simulateGoogleLoginNelayan();
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        icon: const Icon(
                          Icons.g_mobiledata_rounded,
                          size: 28,
                          color: Color(0xFFEA4335),
                        ),
                        label: const Text(
                          'Daftar dengan Google',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF0F2B48),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ==========================================
            // BAGIAN BAWAH: CURVED FOOTER (SOLID OCEAN BLUE)
            // ==========================================
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF0284C7),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(52),
                  topRight: Radius.circular(52),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x330284C7),
                    blurRadius: 18,
                    offset: Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
              child: Column(
                children: [
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Already have an Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFFE0F2FE),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Outlined Capsule Button: Login
                  OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white, width: 1.8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 46,
                        vertical: 11,
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14.5,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapsuleInput({
    required TextEditingController controller,
    required String hintText,
    required String labelText,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixAction,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF0F2B48),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 14,
          ),
          suffixIcon:
              suffixAction ??
              Icon(icon, color: const Color(0xFF334155), size: 22),
        ),
        validator: validator,
      ),
    );
  }
}
