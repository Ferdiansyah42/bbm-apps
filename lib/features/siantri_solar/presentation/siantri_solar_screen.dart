import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion_card.dart';
import '../../../core/widgets/role_switcher_pill.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/models/spbn_settings.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/siantri_models.dart';
import '../providers/siantri_provider.dart';

class SiAntriSolarScreen extends ConsumerStatefulWidget {
  const SiAntriSolarScreen({super.key});

  @override
  ConsumerState<SiAntriSolarScreen> createState() => _SiAntriSolarScreenState();
}

class _SiAntriSolarScreenState extends ConsumerState<SiAntriSolarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fishermanNameController = TextEditingController(text: "Moh. Syafi'i");
  final _recommendationController =
      TextEditingController(text: 'REK-DKP-2026-084');
  final _litersController = TextEditingController();

  BoatEngineTier _selectedEngine = kBoatEngineTiers[1]; // Default: Mesin 15 PK (45 L)

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authNotifierProvider);
    final user = auth.currentUser;
    if (user != null && user.isNelayan) {
      _fishermanNameController.text = user.nama;
      if (user.nomorRekomendasi != null && user.nomorRekomendasi!.isNotEmpty) {
        _recommendationController.text = user.nomorRekomendasi!;
      }
      if (user.kapasitasMesin != null) {
        final matched = kBoatEngineTiers
            .where((t) =>
                t.label == user.kapasitasMesin ||
                user.kapasitasMesin!.contains(t.name))
            .firstOrNull;
        if (matched != null) {
          _selectedEngine = matched;
        }
      }
    }
    _litersController.text = _selectedEngine.maxQuotaLiters.toInt().toString();
  }

  @override
  void dispose() {
    _fishermanNameController.dispose();
    _recommendationController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  void _onEngineChanged(BoatEngineTier? newEngine) {
    if (newEngine == null) return;
    setState(() {
      _selectedEngine = newEngine;
      final currentInput = double.tryParse(_litersController.text) ?? 0;
      if (currentInput > newEngine.maxQuotaLiters || currentInput == 0) {
        _litersController.text = newEngine.maxQuotaLiters.toInt().toString();
      }
    });
  }

  void _fillMaxLiters() {
    setState(() {
      _litersController.text = _selectedEngine.maxQuotaLiters.toInt().toString();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Jumlah permintaan diisi kuota maksimal: ${_selectedEngine.maxQuotaLiters.toInt()} Liter',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _stepLiters(double delta) {
    final current = double.tryParse(_litersController.text) ?? _selectedEngine.maxQuotaLiters;
    final newVal = (current + delta).clamp(5.0, _selectedEngine.maxQuotaLiters);
    setState(() {
      _litersController.text = newVal.toInt().toString();
    });
  }

  void _submitRegistration() {
    if (!_formKey.currentState!.validate()) return;

    final fishermanName = _fishermanNameController.text.trim();
    final recommendationNo = _recommendationController.text.trim().toUpperCase();
    final liters = double.parse(_litersController.text.trim());

    final ticket = ref.read(siAntriProvider.notifier).registerQueue(
          fishermanName: fishermanName,
          recommendationNumber: recommendationNo,
          engineTier: _selectedEngine,
          requestedLiters: liters,
        );

    // 1. Simpan ke activeTicketProvider
    ref.read(activeTicketProvider.notifier).setTicket(ticket);

    // 2. Berpindah otomatis ke tab "Pas QR" (indeks tab Pas QR = 3)
    ref.read(bottomNavIndexProvider.notifier).setIndex(3);

    // 3. Tampilkan snackbar notifikasi singkat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Antrean berhasil dibuat!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  void _showTicketQrDialog(
    BuildContext context, {
    required String queueNumber,
    required String fishermanName,
    required String recommendationNumber,
    required String engineName,
    required double liters,
    required String qrPayload,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2B48),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  queueNumber,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                fishermanName,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$engineName • ${liters.toInt()} Liter',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recommendationNumber,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tunjukkan QR ini ke petugas nozzle SPBN untuk scan barcode & pencairan kuota subsidi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(siAntriProvider);
    final settings = ref.watch(settingsProvider);
    final isAllowed = state.canRegister(settings);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0284C7),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_boat_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'SiAntri Solar Nelayan',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SPBN',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0284C7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    settings.spbnName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan SPBN & Geofencing',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.settings_outlined, color: AppColors.primary, size: 19),
            ),
            onPressed: _openSettings,
          ),
          IconButton(
            tooltip: 'Keluar / Logout',
            icon: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(Icons.logout_rounded, color: AppColors.danger, size: 19),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar dari Akun?'),
                  content: const Text('Anda akan dialihkan kembali ke halaman login.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authNotifierProvider.notifier).logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Keluar'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // RIBBON PENGALIH PERAN CEPAT (PROMINENT & LEGA)
            // ==========================================
            const MotionCard(
              index: 0,
              enableHover: false,
              child: RoleSwitcherPill(isExpanded: true),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // 0. GREETING & STATUS DERMAGA PESISIR (HUMAN TOUCH)
            // ==========================================
            MotionCard(
              index: 1,
              child: _buildHarborGreetingBar(context),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // 1. HEADER & STATUS BAR SPBN (STOK TANGKI)
            // ==========================================
            MotionCard(
              index: 2,
              child: _buildHeaderStatusBar(context, state, settings),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 2. KARTU STATUS GEOFENCING (RADAR DERMAGA)
            // ==========================================
            MotionCard(
              index: 3,
              child: _buildGeofencingStatusCard(context, state, settings),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // BANNER PEMBERITAHUAN TIKET AKTIF (JIKA ADA)
            // ==========================================
            if (state.currentTicket != null) ...[
              MotionCard(
                index: 4,
                child: _buildActiveTicketNoticeBanner(context, state.currentTicket!),
              ),
              const SizedBox(height: 14),
            ],

            // ==========================================
            // 3. MODUL FORM AMBIL NOMOR ANTREAN NELAYAN
            // ==========================================
            MotionCard(
              index: 4,
              enableHover: false,
              child: _buildFishermanRegistrationForm(context, state, settings, isAllowed),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 4. DAFTAR ANTREAN LIVE (FIFO)
            // ==========================================
            MotionCard(
              index: 5,
              child: _buildLiveQueueSection(context, state),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 0: GREETING & STATUS DERMAGA PESISIR
  // ==========================================
  Widget _buildHarborGreetingBar(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);
    final user = auth.currentUser;
    final now = DateTime.now();
    String greeting;
    if (now.hour >= 4 && now.hour < 11) {
      greeting = 'Selamat Pagi';
    } else if (now.hour >= 11 && now.hour < 15) {
      greeting = 'Selamat Siang';
    } else if (now.hour >= 15 && now.hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    final name = (user?.nama != null && user!.nama.isNotEmpty)
        ? user.nama
        : "Moh. Syafi'i";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.waves_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '$greeting, $name',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('⚓', style: TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, size: 12, color: Color(0xFFD97706)),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Selat Madura • Ombak 0.4m (Tenang) • Angin 8 knot',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 6, color: Color(0xFF16A34A)),
                SizedBox(width: 4),
                Text(
                  'Nozzle Siap',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET 1: HEADER & STATUS BAR SPBN
  // ==========================================
  Widget _buildHeaderStatusBar(
    BuildContext context,
    SiAntriState state,
    SpbnSettings settings,
  ) {
    final percentage = (state.tankPercentage * 100).toStringAsFixed(1);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F2B48),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama SPBN & Badge Ketersediaan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.anchor_rounded,
                              color: Color(0xFF93C5FD),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              settings.spbnName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.22),
                        border: Border.all(color: const Color(0xFF34D399)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF34D399),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Solar Tersedia',
                            style: TextStyle(
                              color: Color(0xFF34D399),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Sisa Stok Tangki & Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.opacity_rounded, size: 13, color: Color(0xFF38BDF8)),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Sisa Stok Tangki SPBN',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${AppFormatters.formatNumber(state.tankStockLiters)} L ',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/ ${AppFormatters.formatNumber(state.tankCapacityLiters)} L',
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 13,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      ),
                      child: Text(
                        '$percentage%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress Bar Sisa Stok Tangki
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: state.tankPercentage,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
                  ),
                ),
                const SizedBox(height: 4),
                // Indikator Skala Level Tangki (E - 25% - 50% - 75% - F)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('E', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                      Text('25%', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                      Text('50%', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                      Text('75%', style: TextStyle(color: Color(0xFF64748B), fontSize: 9)),
                      Text('F', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Ringkasan Info Bawah: Antrean Aktif & Estimasi
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.groups_rounded, color: Color(0xFF93C5FD), size: 17),
                            ),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Antrean Aktif',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                                  ),
                                  Text(
                                    '${state.activeQueueCount} Kapal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE047).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.schedule_rounded, color: Color(0xFFFDE047), size: 17),
                            ),
                            const SizedBox(width: 7),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Est. Layanan',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10),
                                  ),
                                  Text(
                                    '~8 Mnt / Kapal',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // ==========================================
  // WIDGET 2: KARTU STATUS GEOFENCING (RADAR DERMAGA)
  // ==========================================
  Widget _buildGeofencingStatusCard(
    BuildContext context,
    SiAntriState state,
    SpbnSettings settings,
  ) {
    if (!settings.isGeofenceEnabled) {
      // ----------------------------------------------------
      // MODE BEBAS UJI (GEOFENCING DINONAKTIFKAN / DEFAULT)
      // ----------------------------------------------------
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Icon(Icons.radar_rounded, color: Color(0xFF2563EB), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDBEAFE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Mode Bebas Uji (Geofencing Dinonaktifkan)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Pendaftaran antrean aktif dari mana saja tanpa pembatasan lokasi GPS.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.tune_rounded, size: 14),
                  label: const Text('Atur', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1D4ED8),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    // ----------------------------------------------------
    // MODE GEOFENCING AKTIF (VALIDASI GPS KETAT)
    // ----------------------------------------------------
    final bool isInside = state.isInsideGeofence;
    final bool isMock = state.isMockLocation;

    Color cardBg;
    Color borderColor;
    Color iconColor;
    IconData statusIcon;
    String badgeTitle;
    String subtitleText;

    if (isMock) {
      cardBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      iconColor = AppColors.danger;
      statusIcon = Icons.warning_amber_rounded;
      badgeTitle = 'TERDETEKSI LOKASI PALSU (FAKE GPS)';
      subtitleText = 'Akses antrean diblokir demi keamanan kuota subsidi nelayan.';
    } else if (isInside) {
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      iconColor = AppColors.success;
      statusIcon = Icons.check_circle_rounded;
      badgeTitle = 'Di Dalam Radius SPBN (${state.currentDistanceMeters.toStringAsFixed(0)} m)';
      subtitleText = 'Lokasi GPS valid di dermaga SPBN (Maks ${settings.radiusMeters.toStringAsFixed(0)} m).';
    } else {
      cardBg = const Color(0xFFFFF7ED);
      borderColor = const Color(0xFFFED7AA);
      iconColor = AppColors.warning;
      statusIcon = Icons.location_off_rounded;
      badgeTitle = 'Di Luar Radius SPBN (${state.currentDistanceMeters.toStringAsFixed(0)} m)';
      subtitleText = 'Tombol pendaftaran terkunci. Dekati dermaga SPBN (Radius ${settings.radiusMeters.toStringAsFixed(0)} m).';
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      badgeTitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, size: 18, color: AppColors.textSecondary),
                tooltip: 'Pengaturan Geofence',
                onPressed: _openSettings,
              ),
            ],
          ),
          const Divider(height: 16),
          // Baris Simulasi Cepat Geofence (Memudahkan Pengujian Tanpa Harus ke Dermaga)
          Row(
            children: [
              const Text(
                'Simulasi:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    InkWell(
                      onTap: () => ref.read(siAntriProvider.notifier).setGeofenceStatus(
                            isInside: true,
                            distance: 35.0,
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isInside && !isMock ? AppColors.successContainer : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Di SPBN (35m)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(siAntriProvider.notifier).setGeofenceStatus(
                            isInside: false,
                            distance: 380.0,
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: !isInside && !isMock ? const Color(0xFFFED7AA) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Di Rumah (380m)', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(siAntriProvider.notifier).setGeofenceStatus(
                            isInside: true,
                            distance: 20.0,
                            isMock: true,
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: isMock ? const Color(0xFFFECACA) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Fake GPS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // BANNER PEMBERITAHUAN TIKET AKTIF
  // ==========================================
  Widget _buildActiveTicketNoticeBanner(BuildContext context, SiAntriTicket ticket) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tiket Aktif: ${ticket.queueNumber} (${ticket.fishermanName})',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.engineTier.name} • ${ticket.requestedLiters.toInt()} L • Est: ${ticket.formattedEstimatedTime}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(bottomNavIndexProvider.notifier).setIndex(3);
            },
            icon: const Icon(Icons.qr_code_2_rounded, size: 16),
            label: const Text(
              'Buka Pas QR',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET 3: FORM AMBIL NOMOR ANTREAN NELAYAN
  // ==========================================
  Widget _buildFishermanRegistrationForm(
    BuildContext context,
    SiAntriState state,
    SpbnSettings settings,
    bool isAllowed,
  ) {
    final currentLiters = double.tryParse(_litersController.text) ?? _selectedEngine.maxQuotaLiters;
    const subsidizedRate = 6800; // Rp 6.800 per liter
    const marketRate = 13500; // Rp 13.500 per liter solar non-subsidi industri
    final totalSubsidized = (currentLiters * subsidizedRate).toInt();
    final totalSaved = (currentLiters * (marketRate - subsidizedRate)).toInt();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Form
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.assignment_add, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ambil Nomor Antrean Nelayan',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Input identitas kapal & rekomendasi DKP',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN 1: KARTU IDENTITAS NELAYAN DKP (VERIFIED SMART CARD)
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F2B48),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F2B48).withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.badge_rounded, color: Color(0xFF93C5FD), size: 16),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'KARTU NELAYAN DKP JAWA TIMUR',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF34D399), width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 11, color: Color(0xFF34D399)),
                            SizedBox(width: 4),
                            Text(
                              'Terverifikasi DKP',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF34D399),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: const Center(
                          child: Icon(Icons.sailing_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fishermanNameController.text.isNotEmpty
                                  ? _fishermanNameController.text
                                  : "Moh. Syafi'i",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Kapal: KM Mina Pasian • Rek: ${_recommendationController.text}',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 1. Input Nama Lengkap Nelayan
            TextFormField(
              controller: _fishermanNameController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Nama Lengkap Nelayan',
                hintText: "Contoh: Moh. Syafi'i",
                prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.primary),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nama nelayan wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            // 2. Input Nomor Surat Rekomendasi / Barcode
            TextFormField(
              controller: _recommendationController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Nomor Surat Rekomendasi / Barcode',
                hintText: 'Contoh: REK-DKP-2026-084',
                prefixIcon: const Icon(Icons.qr_code_rounded, color: AppColors.primary),
                suffixIcon: IconButton(
                  tooltip: 'Gunakan nomor rekomendasi default DKP',
                  icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
                  onPressed: () {
                    setState(() {
                      _recommendationController.text = 'REK-DKP-2026-084';
                    });
                  },
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Nomor surat rekomendasi wajib diisi';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN 2: PILIHAN SPESIFIKASI MESIN KAPAL (TACTILE CARDS)
            // ==========================================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Flexible(
                  child: Text(
                    'Pilih Kapasitas Mesin Kapal:',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Standar DKP Jatim',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: kBoatEngineTiers.map((tier) {
                final isSelected = _selectedEngine.id == tier.id;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _HoverEngineCard(
                      isSelected: isSelected,
                      tier: tier,
                      onTap: () => _onEngineChanged(tier),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 10),

            // Dropdown Kapasitas Mesin Kapal & Kuota Maksimal (Tersinkronisasi)
            DropdownButtonFormField<BoatEngineTier>(
              isExpanded: true,
              key: ValueKey(_selectedEngine.id),
              initialValue: _selectedEngine,
              decoration: const InputDecoration(
                labelText: 'Kapasitas Mesin Kapal & Kuota',
                prefixIcon: Icon(Icons.directions_boat_outlined, color: AppColors.primary),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: kBoatEngineTiers.map((tier) {
                return DropdownMenuItem<BoatEngineTier>(
                  value: tier,
                  child: Text(
                    tier.label,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: _onEngineChanged,
            ),

            const SizedBox(height: 16),

            // ==========================================
            // BAGIAN 3: METERAN PENGISIAN SOLAR SUBSIDI
            // ==========================================
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Volume Permintaan Solar:',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Text(
                          'Maks: ${_selectedEngine.maxQuotaLiters.toInt()} Liter',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Tombol Kurang 5L
                      IconButton(
                        onPressed: () => _stepLiters(-5),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        color: AppColors.primary,
                        tooltip: 'Kurangi 5 Liter',
                      ),
                      // Input Permintaan Solar (Liter)
                      Expanded(
                        child: TextFormField(
                          controller: _litersController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Permintaan Solar (Liter)',
                            hintText: 'Contoh: ${_selectedEngine.maxQuotaLiters.toInt()}',
                            suffixText: 'Liter',
                            prefixIcon: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (val) {
                            final liters = double.tryParse(val ?? '');
                            if (liters == null || liters <= 0) {
                              return 'Jumlah liter harus lebih dari 0';
                            }
                            if (liters > _selectedEngine.maxQuotaLiters) {
                              return 'Maksimal ${_selectedEngine.maxQuotaLiters.toInt()} L untuk ${_selectedEngine.name}';
                            }
                            return null;
                          },
                        ),
                      ),
                      // Tombol Tambah 5L
                      IconButton(
                        onPressed: () => _stepLiters(5),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        color: AppColors.primary,
                        tooltip: 'Tambah 5 Liter',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Pilihan Cepat & Tombol Isi Maksimal
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(
                            child: Text(
                              'Pilihan Cepat:',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: _fillMaxLiters,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE0F2FE),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFBAE6FD)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flash_on_rounded, size: 14, color: Color(0xFF0369A1)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Isi Maksimal',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...[15.0, 30.0, 45.0, 60.0]
                              .where((l) => l <= _selectedEngine.maxQuotaLiters)
                              .map((l) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _litersController.text = l.toInt().toString();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Text(
                                  '${l.toInt()}L',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Estimasi Biaya & Subsidi Pemerintah
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estimasi Biaya Subsidi:',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF166534)),
                              ),
                              Text(
                                'Rp ${AppFormatters.formatNumber(totalSubsidized.toDouble())} (Rp 6.800/L)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF15803D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Hemat Rp ${AppFormatters.formatNumber(totalSaved.toDouble())}',
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF166534),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 5. Tombol Utama "Daftar & Dapatkan Tiket QR"
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isAllowed ? _submitRegistration : null,
                icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                label: Text(
                  isAllowed
                      ? 'Daftar & Dapatkan Tiket QR'
                      : 'Tombol Terkunci (Di Luar Radius SPBN)',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, letterSpacing: 0.3),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9488), // Maritime Emerald Teal
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                  elevation: isAllowed ? 3 : 0,
                  shadowColor: const Color(0xFF0D9488).withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            // Penjelasan tombol saat terkunci
            if (!isAllowed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.danger),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      settings.isGeofenceEnabled
                          ? 'Untuk membuka tombol ini saat di rumah, buka Pengaturan lalu matikan saklar Geofencing (Mode Bebas Uji).'
                          : 'Stok solar SPBN habis atau data tidak valid.',
                      style: const TextStyle(fontSize: 11, color: AppColors.danger),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 4: DAFTAR ANTREAN LIVE (FIFO)
  // ==========================================
  Widget _buildLiveQueueSection(BuildContext context, SiAntriState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.format_list_numbered_rounded, color: AppColors.primary, size: 19),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Daftar Antrean Live (FIFO)',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${state.liveQueues.length} Kapal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.liveQueues.length,
            separatorBuilder: (_, _) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final queue = state.liveQueues[index];
              final isServing = queue.isServing;

              return Row(
                children: [
                  // Badge Kode Antrean
                  Container(
                    width: 78,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isServing
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isServing ? const Color(0xFF34D399) : const Color(0xFFCBD5E1),
                        width: isServing ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          queue.queueNumber,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: isServing ? const Color(0xFF047857) : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isServing ? 'Dilayani' : 'Menunggu',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isServing ? const Color(0xFF047857) : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info Nelayan & Kapal
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          queue.fishermanName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  queue.engineName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${queue.liters.toInt()} L',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accentWarm,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          queue.recommendationNumber,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.textMuted,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tombol "Lihat QR"
                  OutlinedButton.icon(
                    onPressed: () => _showTicketQrDialog(
                      context,
                      queueNumber: queue.queueNumber,
                      fishermanName: queue.fishermanName,
                      recommendationNumber: queue.recommendationNumber,
                      engineName: queue.engineName,
                      liters: queue.liters,
                      qrPayload: queue.qrData,
                    ),
                    icon: const Icon(Icons.qr_code_rounded, size: 15),
                    label: const Text('QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Card pilihan mesin kapal dengan animasi hover & micro-interaction
class _HoverEngineCard extends StatefulWidget {
  final bool isSelected;
  final BoatEngineTier tier;
  final VoidCallback onTap;

  const _HoverEngineCard({
    required this.isSelected,
    required this.tier,
    required this.onTap,
  });

  @override
  State<_HoverEngineCard> createState() => _HoverEngineCardState();
}

class _HoverEngineCardState extends State<_HoverEngineCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..translateByDouble(0.0, _isHovered ? -3.0 : 0.0, 0.0, 1.0),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFFEFF6FF)
                : (_isHovered ? const Color(0xFFF1F5F9) : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.primary
                  : (_isHovered ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0)),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: widget.isSelected || _isHovered
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(
                        alpha: widget.isSelected ? 0.18 : 0.10,
                      ),
                      blurRadius: _isHovered ? 10 : 8,
                      offset: Offset(0, _isHovered ? 4 : 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Icon(
                widget.tier.id == 'pk_30'
                    ? Icons.directions_boat_rounded
                    : Icons.sailing_rounded,
                size: 20,
                color: widget.isSelected
                    ? AppColors.primary
                    : (_isHovered ? AppColors.primary : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                widget.tier.name.replaceAll('Mesin ', ''),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: widget.isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 1),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? const Color(0xFFDBEAFE)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.tier.maxQuotaLiters.toInt()}L',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

