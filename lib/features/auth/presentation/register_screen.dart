import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final _rekomendasiController = TextEditingController(text: 'REK-DKP-2026-099');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  BoatEngineTier _selectedEngine = kBoatEngineTiers[1]; // Default 15 PK (45 L)
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _rekomendasiController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

    final success = await ref.read(authNotifierProvider.notifier).register(newAccount);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pendaftaran berhasil! Selamat datang, $nama'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Kembali jika dipush dari login
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Pendaftaran gagal';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daftar Akun Nelayan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.app_registration_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registrasi Nelayan SPBN',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Daftarkan identitas kapal & surat rekomendasi DKP untuk verifikasi kuota solar subsidi.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Form Card
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: AppColors.border),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Nama Lengkap Nelayan
                        TextFormField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap Nelayan',
                            hintText: "Contoh: Moh. Syafi'i",
                            prefixIcon: Icon(Icons.person_outline_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama lengkap nelayan wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // 2. Alamat Email / Gmail Nelayan
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Email / Gmail',
                            hintText: 'Contoh: syafii.nelayan@gmail.com',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Alamat Email / Gmail wajib diisi';
                            }
                            final clean = val.trim().toLowerCase();
                            if (!clean.contains('@') || !clean.contains('.')) {
                              return 'Format email tidak valid (contoh: nelayan@gmail.com)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // 3. Nomor HP / WhatsApp
                        TextFormField(
                          controller: _noHpController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Nomor Handphone / WhatsApp',
                            hintText: 'Contoh: 081234567890',
                            prefixIcon: Icon(Icons.phone_android_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nomor HP wajib diisi';
                            }
                            if (val.trim().length < 10) {
                              return 'Minimal 10 digit angka';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // 4. Nomor Surat Rekomendasi DKP
                        TextFormField(
                          controller: _rekomendasiController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Surat Rekomendasi DKP',
                            hintText: 'Contoh: REK-DKP-2026-099',
                            prefixIcon: Icon(Icons.assignment_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nomor surat rekomendasi wajib diisi';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // 5. Dropdown Kapasitas Mesin Kapal & Kuota Maksimal
                        DropdownButtonFormField<BoatEngineTier>(
                          initialValue: _selectedEngine,
                          decoration: const InputDecoration(
                            labelText: 'Kapasitas Mesin Kapal & Kuota',
                            prefixIcon: Icon(Icons.directions_boat_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          items: kBoatEngineTiers.map((tier) {
                            return DropdownMenuItem<BoatEngineTier>(
                              value: tier,
                              child: Text(
                                tier.label,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedEngine = val);
                          },
                        ),

                        const SizedBox(height: 14),

                        // 6. Password
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi / Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Password wajib diisi';
                            }
                            if (val.trim().length < 6) {
                              return 'Minimal 6 karakter';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        // 7. Konfirmasi Password
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirm,
                          decoration: InputDecoration(
                            labelText: 'Konfirmasi Kata Sandi',
                            prefixIcon: const Icon(Icons.lock_reset_rounded),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ),
                          validator: (val) {
                            if (val != _passwordController.text) {
                              return 'Konfirmasi kata sandi tidak cocok';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Tombol Daftar & Masuk
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: authState.isLoading ? null : _handleRegister,
                            icon: authState.isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.how_to_reg_rounded),
                            label: Text(
                              authState.isLoading ? 'Mendaftarkan...' : 'Daftar & Masuk',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
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

                const SizedBox(height: 16),

                // Link Kembali ke Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah memiliki akun nelayan? ',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Masuk di sini',
                        style: TextStyle(
                          fontSize: 13,
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
      ),
    );
  }
}
