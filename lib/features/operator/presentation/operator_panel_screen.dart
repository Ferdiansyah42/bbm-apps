import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/motion_card.dart';
import '../../../core/widgets/role_switcher_pill.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../settings/providers/settings_provider.dart';
import '../../siantri_solar/models/siantri_models.dart';
import '../../siantri_solar/providers/siantri_provider.dart';

class OperatorPanelScreen extends ConsumerStatefulWidget {
  const OperatorPanelScreen({super.key});

  @override
  ConsumerState<OperatorPanelScreen> createState() => _OperatorPanelScreenState();
}

class _OperatorPanelScreenState extends ConsumerState<OperatorPanelScreen> {
  final _verifyController = TextEditingController();
  Map<String, dynamic>? _verificationResult;

  @override
  void dispose() {
    _verifyController.dispose();
    super.dispose();
  }

  void _checkTicketValidity(SiAntriState state) {
    final query = _verifyController.text.trim().toUpperCase();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ketik nomor antrean (SLR-XXX) atau nomor rekomendasi'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Cari di live queues
    final inLive = state.liveQueues.where(
      (q) => q.queueNumber.toUpperCase() == query ||
             q.recommendationNumber.toUpperCase().contains(query),
    ).firstOrNull;

    // Cari di tiket aktif
    final active = (state.currentTicket != null &&
            (state.currentTicket!.queueNumber.toUpperCase() == query ||
             state.currentTicket!.recommendationNumber.toUpperCase().contains(query)))
        ? state.currentTicket
        : null;

    // Cari di riwayat selesai
    final inHistory = state.completedTransactions.where(
      (t) => t.queueNumber.toUpperCase() == query ||
             t.recommendationNumber.toUpperCase().contains(query),
    ).firstOrNull;

    if (inLive != null) {
      final engineMax = _getMaxQuotaForEngine(inLive.engineName);
      final isAnomaly = inLive.liters > engineMax;
      setState(() {
        _verificationResult = {
          'isValid': true,
          'statusText': inLive.isServing ? 'Sedang Dilayani di Nozzle' : 'Menunggu Giliran',
          'queueNumber': inLive.queueNumber,
          'fishermanName': inLive.fishermanName,
          'recommendation': inLive.recommendationNumber,
          'engineName': inLive.engineName,
          'liters': inLive.liters,
          'isAnomaly': isAnomaly,
          'anomalyScore': isAnomaly ? 0.89 : 0.12,
          'anomalyMessage': isAnomaly
              ? 'Peringatan: Permintaan ${inLive.liters.toInt()}L melebihi kuota wajar ${inLive.engineName} ($engineMax L)!'
              : 'Skor Anomali Normal: Data konsisten dengan profil kapal DKP.',
        };
      });
    } else if (active != null) {
      final engineMax = active.engineTier.maxQuotaLiters;
      final isAnomaly = active.requestedLiters > engineMax;
      setState(() {
        _verificationResult = {
          'isValid': true,
          'statusText': 'Terdaftar Aktif (Mode Nelayan)',
          'queueNumber': active.queueNumber,
          'fishermanName': active.fishermanName,
          'recommendation': active.recommendationNumber,
          'engineName': active.engineTier.name,
          'liters': active.requestedLiters,
          'isAnomaly': isAnomaly,
          'anomalyScore': isAnomaly ? 0.89 : 0.12,
          'anomalyMessage': isAnomaly
              ? 'Peringatan: Permintaan melebihi kuota mesin kapal!'
              : 'Skor Anomali Normal: Verifikasi sukses.',
        };
      });
    } else if (inHistory != null) {
      setState(() {
        _verificationResult = {
          'isValid': true,
          'statusText': 'Sudah Selesai Diisi Hari Ini',
          'queueNumber': inHistory.queueNumber,
          'fishermanName': inHistory.fishermanName,
          'recommendation': inHistory.recommendationNumber,
          'engineName': inHistory.engineName,
          'liters': inHistory.liters,
          'isAnomaly': false,
          'anomalyScore': 0.05,
          'anomalyMessage': 'Transaksi telah dituntaskan pada ${inHistory.formattedTime}.',
        };
      });
    } else {
      setState(() {
        _verificationResult = {
          'isValid': false,
          'message': 'Tiket atau Barcode "$query" tidak ditemukan di SPBN ini.',
        };
      });
    }
  }

  double _getMaxQuotaForEngine(String engineName) {
    for (final tier in kBoatEngineTiers) {
      if (engineName.contains(tier.name) || tier.name.contains(engineName)) {
        return tier.maxQuotaLiters;
      }
    }
    return 60.0;
  }

  void _completeServing() {
    final tx = ref.read(siAntriProvider.notifier).completeCurrentServing();
    if (tx != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengisian ${tx.liters.toInt()} L untuk ${tx.fishermanName} (${tx.queueNumber}) selesai diverifikasi!',
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _skipServing() {
    final skipped = ref.read(siAntriProvider.notifier).skipCurrentServing();
    if (skipped != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Antrean ${skipped.queueNumber} dilewati. Antrean berikutnya dimajukan.'),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addStock() {
    ref.read(siAntriProvider.notifier).addTankStock(4000.0);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bongkar tangki sukses! Saldo solar SPBN bertambah +4.000 Liter.'),
        backgroundColor: Color(0xFF0284C7),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(siAntriProvider);
    final settings = ref.watch(settingsProvider);
    final serving = state.currentServingQueue;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Dark slate for operator
        foregroundColor: Colors.white,
        elevation: 2,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Operator SPBN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Pengawas & Petugas Dispenser',
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Pengaturan Geofence',
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Keluar / Logout',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Keluar dari Akun Operator?'),
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ribbon Pengalih Peran Cepat (Lega & Nyaman)
            const MotionCard(
              index: 0,
              enableHover: false,
              child: RoleSwitcherPill(isExpanded: true),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 1. RINGKASAN ATAS: STATUS TANGKI & ANTREAN OPERATOR
            // ==========================================
            MotionCard(
              index: 1,
              child: _buildOperatorSummaryCard(context, state, settings),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 2. KARTU KONTROL DISPENSER — SEDANG DILAYANI
            // ==========================================
            MotionCard(
              index: 2,
              child: _buildDispenserControlCard(context, serving),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 3. KARTU VERIFIKASI CEPAT TIKET / QR CODE & DETEKSI ANOMALI
            // ==========================================
            MotionCard(
              index: 3,
              enableHover: false,
              child: _buildQuickVerificationCard(context, state),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 4. KARTU MANAJEMEN STOK TANGKI SPBN
            // ==========================================
            MotionCard(
              index: 4,
              child: _buildTankManagementCard(context, state),
            ),

            const SizedBox(height: 14),

            // ==========================================
            // 5. RIWAYAT PENGISIAN SELESAI HARI INI
            // ==========================================
            MotionCard(
              index: 5,
              child: _buildCompletedTransactionsCard(context, state),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // WIDGET 1: RINGKASAN ATAS OPERATOR
  // ==========================================
  Widget _buildOperatorSummaryCard(
    BuildContext context,
    SiAntriState state,
    dynamic settings,
  ) {
    Color statusBg;
    Color statusTextColor;
    switch (state.solarStatus) {
      case SolarAvailabilityStatus.available:
        statusBg = const Color(0xFF10B981);
        statusTextColor = Colors.white;
        break;
      case SolarAvailabilityStatus.runningLow:
        statusBg = const Color(0xFFF59E0B);
        statusTextColor = Colors.white;
        break;
      case SolarAvailabilityStatus.empty:
        statusBg = const Color(0xFFEF4444);
        statusTextColor = Colors.white;
        break;
      case SolarAvailabilityStatus.tankerOtw:
        statusBg = const Color(0xFF3B82F6);
        statusTextColor = Colors.white;
        break;
    }

    final servingCode = state.currentServingQueue?.queueNumber ?? 'Standby';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.storefront_rounded, color: Color(0xFF38BDF8), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        settings.spbnName ?? 'SPBN Madura',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  state.solarStatus.label,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Stok Tangki Meter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sisa Stok Tangki Solar',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Text(
                '${(state.tankPercentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: state.tankPercentage,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF38BDF8)),
            ),
          ),

          const SizedBox(height: 14),

          // 2 Kotak Status: Sedang Dilayani & Jumlah Menunggu
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Di Dispenser',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        servingCode,
                        style: const TextStyle(
                          color: Color(0xFF34D399),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kapal Menunggu',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.waitingQueueCount} Kapal',
                        style: const TextStyle(
                          color: Color(0xFFFDE047),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
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
  // WIDGET 2: KARTU KONTROL DISPENSER
  // ==========================================
  Widget _buildDispenserControlCard(BuildContext context, LiveQueueItem? serving) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                  Icon(Icons.local_gas_station_rounded, color: Color(0xFF0D9488), size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Kontrol Dispenser — Sedang Dilayani',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (serving != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'NOZZLE ON',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                ),
            ],
          ),

          const Divider(height: 20),

          if (serving != null) ...[
            // Banner Nomor Antrean
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F766E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NOMOR ANTREAN AKTIF',
                        style: TextStyle(color: Color(0xFFCCFBF1), fontSize: 10, letterSpacing: 0.8),
                      ),
                      Text(
                        serving.queueNumber,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${serving.liters.toInt()} LITER',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Rincian Nelayan
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildKeyValueRow('Nama Nelayan', serving.fishermanName, icon: Icons.person),
                  const SizedBox(height: 6),
                  _buildKeyValueRow('Surat Rekomendasi', serving.recommendationNumber, icon: Icons.qr_code),
                  const SizedBox(height: 6),
                  _buildKeyValueRow('Kapasitas Mesin', serving.engineName, icon: Icons.directions_boat),
                  const SizedBox(height: 6),
                  _buildKeyValueRow('Volume Diisi', '${serving.liters.toInt()} Liter Solar',
                      icon: Icons.water_drop, isHighlight: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tombol Aksi Operator
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _completeServing,
                    icon: const Icon(Icons.check_circle_rounded, size: 18),
                    label: const Text(
                      'Verifikasi & Selesaikan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: _skipServing,
                    icon: const Icon(Icons.skip_next_rounded, size: 18),
                    label: const Text(
                      'Lewati',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD97706),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.hourglass_empty_rounded, size: 38, color: Color(0xFF94A3B8)),
                  SizedBox(height: 8),
                  Text(
                    'Dispenser Standby',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tidak ada antrean kapal yang aktif saat ini. Beralih ke "Mode Nelayan" di atas untuk mendaftarkan antrean baru.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET 3: KARTU VERIFIKASI CEPAT TIKET / QR
  // ==========================================
  Widget _buildQuickVerificationCard(BuildContext context, SiAntriState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.document_scanner_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Verifikasi Cepat Tiket / QR Code',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Ketik nomor antrean atau nomor surat rekomendasi untuk cek keabsahan & anomali kuota.',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verifyController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'Contoh: SLR-002 atau REK-DKP',
                    prefixIcon: Icon(Icons.search_rounded),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                  onSubmitted: (_) => _checkTicketValidity(state),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _checkTicketValidity(state),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Cek', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          // Hasil Verifikasi
          if (_verificationResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _verificationResult!['isValid'] == true
                    ? (_verificationResult!['isAnomaly'] == true
                        ? const Color(0xFFFEF2F2)
                        : const Color(0xFFF0FDF4))
                    : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _verificationResult!['isValid'] == true
                      ? (_verificationResult!['isAnomaly'] == true
                          ? const Color(0xFFF87171)
                          : const Color(0xFF86EFAC))
                      : const Color(0xFFFCD34D),
                ),
              ),
              child: _verificationResult!['isValid'] == true
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _verificationResult!['isAnomaly'] == true
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_rounded,
                              color: _verificationResult!['isAnomaly'] == true
                                  ? AppColors.danger
                                  : AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '${_verificationResult!['queueNumber']} • ${_verificationResult!['statusText']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _verificationResult!['isAnomaly'] == true
                                      ? AppColors.danger
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Nelayan: ${_verificationResult!['fishermanName']} | Rekomendasi: ${_verificationResult!['recommendation']}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                        ),
                        Text(
                          '${_verificationResult!['engineName']} • Permintaan: ${_verificationResult!['liters'].toInt()} L',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        const Divider(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _verificationResult!['isAnomaly'] == true
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF10B981),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Score: ${_verificationResult!['anomalyScore']}',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _verificationResult!['anomalyMessage'],
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: _verificationResult!['isAnomaly'] == true
                                      ? const Color(0xFF991B1B)
                                      : const Color(0xFF166534),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Text(
                      _verificationResult!['message'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFFB45309)),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET 4: MANAJEMEN STOK TANGKI SPBN
  // ==========================================
  Widget _buildTankManagementCard(BuildContext context, SiAntriState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Manajemen Status & Saldo Tangki SPBN',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ubah status ketersediaan solar yang langsung tampil pada layar nelayan:',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),

          // Pilihan Status Ketersediaan
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SolarAvailabilityStatus.values.map((status) {
              final isSelected = state.solarStatus == status;
              Color chipColor;
              switch (status) {
                case SolarAvailabilityStatus.available:
                  chipColor = const Color(0xFF10B981);
                  break;
                case SolarAvailabilityStatus.runningLow:
                  chipColor = const Color(0xFFF59E0B);
                  break;
                case SolarAvailabilityStatus.empty:
                  chipColor = const Color(0xFFEF4444);
                  break;
                case SolarAvailabilityStatus.tankerOtw:
                  chipColor = const Color(0xFF3B82F6);
                  break;
              }

              return ChoiceChip(
                label: Text(status.label),
                selected: isSelected,
                selectedColor: chipColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? chipColor : AppColors.textSecondary,
                ),
                side: BorderSide(color: isSelected ? chipColor : const Color(0xFFCBD5E1)),
                onSelected: (_) {
                  ref.read(siAntriProvider.notifier).setSolarStatus(status);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Status SPBN diubah menjadi: "${status.label}"'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Tombol Tambah Stok / Bongkar Tangki
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addStock,
              icon: const Icon(Icons.local_shipping_rounded, size: 18),
              label: const Text(
                '+ Tambah Stok / Bongkar Tangki (+4.000 Liter)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDGET 5: RIWAYAT PENGISIAN SELESAI HARI INI
  // ==========================================
  Widget _buildCompletedTransactionsCard(BuildContext context, SiAntriState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Riwayat Pengisian Selesai Hari Ini',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${state.completedTransactions.length} Kapal',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.water_drop_rounded, size: 14, color: Color(0xFF0284C7)),
                const SizedBox(width: 6),
                Text(
                  'Total Solar Tersalur Hari Ini: ${state.totalLitersDispensedToday.toInt()} Liter',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          if (state.completedTransactions.isNotEmpty)
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.completedTransactions.length,
              separatorBuilder: (_, _) => const Divider(height: 14),
              itemBuilder: (context, index) {
                final tx = state.completedTransactions[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Color(0xFF166534)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${tx.queueNumber} • ${tx.fishermanName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '${tx.liters.toInt()} L',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${tx.engineName} • ${tx.recommendationNumber}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              Text(
                                tx.formattedTime,
                                style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text('Belum ada transaksi selesai hari ini',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKeyValueRow(String key, String value, {required IconData icon, bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(key, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isHighlight ? 13 : 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            color: isHighlight ? const Color(0xFF0F766E) : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
