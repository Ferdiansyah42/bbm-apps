import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/role_switcher_pill.dart';
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

  void _showTicketQrDialog(BuildContext context, {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  queueNumber,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fishermanName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$engineName • ${liters.toInt()} Liter',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrPayload,
                  version: QrVersions.auto,
                  size: 190,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                recommendationNumber,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tunjukkan QR ini ke petugas nozzle SPBN untuk verifikasi kuota',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_boat_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SiAntri Solar Nelayan',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 0.4,
                    ),
                  ),
                  Text(
                    settings.spbnName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          const RoleSwitcherPill(),
          IconButton(
            tooltip: 'Pengaturan SPBN & Geofencing',
            icon: const Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // 1. HEADER & STATUS BAR SPBN (STOK TANGKI)
            // ==========================================
            _buildHeaderStatusBar(context, state, settings),

            const SizedBox(height: 14),

            // ==========================================
            // 2. KARTU STATUS GEOFENCING (MENGIKUTI SAKLAR)
            // ==========================================
            _buildGeofencingStatusCard(context, state, settings),

            const SizedBox(height: 14),

            // ==========================================
            // BANNER PEMBERITAHUAN TIKET AKTIF (JIKA ADA)
            // ==========================================
            if (state.currentTicket != null) ...[
              _buildActiveTicketNoticeBanner(context, state.currentTicket!),
              const SizedBox(height: 14),
            ],

            // ==========================================
            // 3. MODUL FORM AMBIL NOMOR ANTREAN NELAYAN (SELALU TAMPIL)
            // ==========================================
            _buildFishermanRegistrationForm(context, state, settings, isAllowed),

            const SizedBox(height: 14),

            // ==========================================
            // 4. DAFTAR ANTREAN LIVE (FIFO)
            // ==========================================
            _buildLiveQueueSection(context, state),

            const SizedBox(height: 24),
          ],
        ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B48), Color(0xFF1E4976)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2B48).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
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
                    const Icon(
                      Icons.anchor_rounded,
                      color: Color(0xFF93C5FD),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        settings.spbnName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  border: Border.all(color: const Color(0xFF34D399)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 13),
                    SizedBox(width: 4),
                    Text(
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

          const SizedBox(height: 14),

          // Sisa Stok Tangki & Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sisa Stok Tangki SPBN',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${AppFormatters.formatNumber(state.tankStockLiters)} L ',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
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
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
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

          const SizedBox(height: 8),

          // Progress Bar Sisa Stok Tangki
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.tankPercentage,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),

          const SizedBox(height: 14),

          // Ringkasan Info Bawah: Antrean Aktif & Estimasi
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, color: Color(0xFF93C5FD), size: 18),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Antrean Aktif',
                              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                          Text('${state.activeQueueCount} Kapal',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: Color(0xFFFDE047), size: 18),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Est. Layanan',
                              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 10)),
                          Text('~8 Menit / Kapal',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
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
  // WIDGET 2: KARTU STATUS GEOFENCING (MENGIKUTI SAKLAR)
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
          color: const Color(0xFFEFF6FF), // Soft Blue
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFBFDBFE), width: 1.2),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: _openSettings,
                  icon: const Icon(Icons.settings, size: 14),
                  label: const Text('Atur', style: TextStyle(fontSize: 12)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(12),
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isInside && !isMock ? AppColors.successContainer : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Di SPBN (35m)', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(siAntriProvider.notifier).setGeofenceStatus(
                            isInside: false,
                            distance: 380.0,
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: !isInside && !isMock ? const Color(0xFFFED7AA) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Di Rumah (380m)', style: TextStyle(fontSize: 10)),
                      ),
                    ),
                    InkWell(
                      onTap: () => ref.read(siAntriProvider.notifier).setGeofenceStatus(
                            isInside: true,
                            distance: 20.0,
                            isMock: true,
                          ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isMock ? const Color(0xFFFECACA) : Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text('Fake GPS', style: TextStyle(fontSize: 10)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
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
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ticket.engineTier.name} • ${ticket.requestedLiters.toInt()} L • Est: ${ticket.formattedEstimatedTime}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF047857)),
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET 3: KARTU TIKET ANTREAN DIGITAL (BOARDING PASS)
  // ==========================================
  Widget _buildDigitalTicketBoardingPass(
    BuildContext context,
    SiAntriTicket ticket,
    SpbnSettings settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Header Boarding Pass
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F2B48), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BOARDING PASS ANTREAN SOLAR',
                      style: TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ticket.queueNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Menunggu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Garis Putus-Putus Perforasi Khas Tiket
          _buildTicketDottedDivider(),

          // Body Rincian Tiket Nelayan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'NAMA NELAYAN',
                        value: ticket.fishermanName,
                        icon: Icons.person_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'SURAT REKOMENDASI DKP',
                        value: ticket.recommendationNumber,
                        icon: Icons.assignment_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'KAPASITAS MESIN',
                        value: ticket.engineTier.name,
                        icon: Icons.directions_boat_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'KUOTA SOLAR DIMINTA',
                        value: '${ticket.requestedLiters.toInt()} Liter',
                        icon: Icons.local_gas_station_rounded,
                        isHighlight: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'ESTIMASI PENGISIAN',
                        value: ticket.formattedEstimatedTime,
                        icon: Icons.access_time_filled_rounded,
                      ),
                    ),
                    Expanded(
                      child: _buildTicketDetailItem(
                        label: 'LOKASI SPBN',
                        value: settings.spbnName.split('-').first.trim(),
                        icon: Icons.storefront_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Garis Putus-Putus Perforasi Sebelum QR
          _buildTicketDottedDivider(),

          // Bagian QR Code & Aksi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: QrImageView(
                    data: ticket.qrData,
                    version: QrVersions.auto,
                    size: 160,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.qrData,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tunjukkan QR ini ke petugas nozzle SPBN untuk scan barcode & pencairan kuota.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showTicketQrDialog(
                          context,
                          queueNumber: ticket.queueNumber,
                          fishermanName: ticket.fishermanName,
                          recommendationNumber: ticket.recommendationNumber,
                          engineName: ticket.engineTier.name,
                          liters: ticket.requestedLiters,
                          qrPayload: ticket.qrData,
                        ),
                        icon: const Icon(Icons.fullscreen_rounded, size: 18),
                        label: const Text('Perbesar QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(siAntriProvider.notifier).cancelTicket();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Tiket antrean berhasil dibatalkan'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.cancel_outlined, size: 18),
                        label: const Text('Batal Antre'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
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
    );
  }

  Widget _buildTicketDottedDivider() {
    return Row(
      children: [
        // Lekukan kiri
        Container(
          width: 12,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final dashCount = (constraints.constrainWidth() / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(dashCount, (_) {
                  return const SizedBox(
                    width: dashWidth,
                    height: 1.5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        // Lekukan kanan
        Container(
          width: 12,
          height: 24,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              bottomLeft: Radius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketDetailItem({
    required String label,
    required String value,
    required IconData icon,
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary : AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ==========================================
  // WIDGET 4: FORM AMBIL NOMOR ANTREAN NELAYAN
  // ==========================================
  Widget _buildFishermanRegistrationForm(
    BuildContext context,
    SiAntriState state,
    SpbnSettings settings,
    bool isAllowed,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Form
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.assignment_add, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ambil Nomor Antrean Nelayan',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Input identitas kapal & rekomendasi DKP',
                          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: 24),

              // 1. Input Nama Lengkap Nelayan
              TextFormField(
                controller: _fishermanNameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap Nelayan',
                  hintText: "Contoh: Moh. Syafi'i",
                  prefixIcon: Icon(Icons.person_outline_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
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
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Nomor Surat Rekomendasi / Barcode',
                  hintText: 'Contoh: REK-DKP-2026-084',
                  prefixIcon: const Icon(Icons.qr_code_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Gunakan nomor rekomendasi default DKP',
                    icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
                    onPressed: () {
                      _recommendationController.text = 'REK-DKP-2026-084';
                    },
                  ),
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
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

              const SizedBox(height: 12),

              // 3. Dropdown Kapasitas Mesin Kapal & Kuota Maksimal
              DropdownButtonFormField<BoatEngineTier>(
                value: _selectedEngine,
                decoration: const InputDecoration(
                  labelText: 'Kapasitas Mesin Kapal & Kuota',
                  prefixIcon: Icon(Icons.directions_boat_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                onChanged: _onEngineChanged,
              ),

              const SizedBox(height: 12),

              // 4. Input Jumlah Permintaan (Liter) & Tombol Pintas "Isi Maksimal"
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _litersController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: 'Permintaan Solar (Liter)',
                        hintText: 'Contoh: ${_selectedEngine.maxQuotaLiters.toInt()}',
                        suffixText: 'Liter',
                        prefixIcon: const Icon(Icons.local_gas_station_rounded),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
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
                  const SizedBox(width: 8),
                  // Tombol Pintas "Isi Maksimal"
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _fillMaxLiters,
                      icon: const Icon(Icons.flash_on_rounded, size: 16),
                      label: const Text(
                        'Isi Maksimal',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE0F2FE),
                        foregroundColor: const Color(0xFF0369A1),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFFBAE6FD)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 5. Tombol Hijau Utama "Daftar & Dapatkan Tiket QR"
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isAllowed ? _submitRegistration : null,
                  icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                  label: Text(
                    isAllowed
                        ? 'Daftar & Dapatkan Tiket QR'
                        : 'Tombol Terkunci (Di Luar Radius SPBN)',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488), // Maritime Emerald Teal
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    disabledForegroundColor: Colors.grey.shade600,
                    elevation: isAllowed ? 2 : 0,
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
      ),
    );
  }

  // ==========================================
  // WIDGET 5: DAFTAR ANTREAN LIVE (FIFO)
  // ==========================================
  Widget _buildLiveQueueSection(BuildContext context, SiAntriState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.format_list_numbered_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Daftar Antrean Live (FIFO)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.liveQueues.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final queue = state.liveQueues[index];
              final isServing = queue.isServing;

              return Row(
                children: [
                  // Badge Kode Antrean
                  Container(
                    width: 72,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isServing
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isServing ? const Color(0xFF34D399) : const Color(0xFFCBD5E1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          queue.queueNumber,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: isServing ? const Color(0xFF047857) : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          isServing ? 'Dilayani' : 'Menunggu',
                          style: TextStyle(
                            fontSize: 9,
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
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${queue.engineName} • ${queue.liters.toInt()} L',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          queue.recommendationNumber,
                          style: const TextStyle(
                            fontSize: 10,
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
                    label: const Text('QR', style: TextStyle(fontSize: 11)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
