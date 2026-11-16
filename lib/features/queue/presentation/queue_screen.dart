import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/models.dart';
import '../../../core/repositories/mock_spbn_repository.dart';
import '../../../core/security/location_security_service.dart';
import '../../../core/utils/formatters.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  bool _isSubmitting = false;

  Future<void> _handleTakeQueue(GeofenceSecurityState geofence) async {
    setState(() => _isSubmitting = true);
    try {
      final pos = geofence.position;
      final ticket = await ref.read(activeQueueNotifierProvider.notifier).takeQueue(
            userLat: pos?.latitude ?? AppConstants.defaultSpbnLatitude,
            userLon: pos?.longitude ?? AppConstants.defaultSpbnLongitude,
            isMocked: geofence.isMocked,
            accuracy: geofence.accuracy ?? 10.0,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor antrean berhasil diterbitkan: ${ticket.queueCode}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleCancelQueue(int ticketId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Antrean?'),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan nomor antrean ini? Posisi prioritas antrean Anda akan dilepas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(activeQueueNotifierProvider.notifier).cancelQueue(ticketId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Antrean Anda telah dibatalkan.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(activeQueueNotifierProvider);
    final geofenceState = ref.watch(geofenceSecurityNotifierProvider);
    final letterAsync = ref.watch(recommendationLetterProvider);

    final QueueTicket? activeTicket = queueAsync.value;
    final bool hasActiveQueue = activeTicket != null && activeTicket.isWaiting;

    final geofence = geofenceState.value;
    final bool isGeofenceValid = geofence?.canTakeQueue ?? false;
    final bool isQuotaAvailable = letterAsync.value?.isQuotaAvailable ?? true;
    final bool canTakeQueue = isGeofenceValid && isQuotaAvailable && !hasActiveQueue;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Antrean Solar Prioritas'),
        actions: [
          IconButton(
            tooltip: 'Segarkan Status Antrean',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              ref.read(activeQueueNotifierProvider.notifier).refreshQueue();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasActiveQueue)
              // KARTU TIKET ANTREAN AKTIF
              _buildActiveTicketCard(context, activeTicket!)
            else
              // TAMPILAN BELUM MENGAMBIL ANTREAN
              _buildNoTicketCard(context, geofence, canTakeQueue, isQuotaAvailable),

            const SizedBox(height: 20),

            // KARTU PERSYARATAN VALIDASI SPASIAL
            _buildRequirementsStatusCard(context, geofence, isQuotaAvailable, hasActiveQueue),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTicketCard(BuildContext context, QueueTicket ticket) {
    return Card(
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time_filled_rounded, size: 16, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'MENUNGGU GILIRAN SPBN',
                    style: TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'NOMOR TIKET ANDA',
              style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.queueCode,
              style: const TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 10),

            // Skor Prioritas & Estimasi
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Skor Prioritas (Sp)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          ticket.priorityScore.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.secondary),
                        ),
                        const Text('Nelayan Tradisional', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: AppColors.border),
                  Expanded(
                    child: Column(
                      children: [
                        const Text('Estimasi Tunggu', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 2),
                        Text(
                          '~${ticket.estimatedWaitMinutes} Menit',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        const Text('Waktu Pelayanan', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Check-in: ${AppFormatters.formatTime(ticket.createdAt)} WIB',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _handleCancelQueue(ticket.id),
              icon: const Icon(Icons.cancel_outlined, size: 18),
              label: const Text('Batalkan Tiket Antrean'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: AppColors.danger),
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoTicketCard(
    BuildContext context,
    GeofenceSecurityState? geofence,
    bool canTakeQueue,
    bool isQuotaAvailable,
  ) {
    return Card(
      elevation: 1,
      shadowColor: AppColors.primary.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: canTakeQueue ? AppColors.successContainer : AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.confirmation_number_rounded,
                size: 44,
                color: canTakeQueue ? AppColors.success : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Belum Memiliki Antrean',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ambil nomor antrean prioritas SPBN dengan memvalidasi posisi GPS Anda di area fisik dermaga (radius 100 meter).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 22),

            // Tombol Utama Ambil Antrean
            FilledButton(
              onPressed: canTakeQueue && !_isSubmitting ? () => _handleTakeQueue(geofence!) : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: canTakeQueue ? 2 : 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ambil Nomor Antrean',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),

            if (!canTakeQueue) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warningContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getDisabledReason(geofence, isQuotaAvailable),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getDisabledReason(GeofenceSecurityState? geofence, bool isQuotaAvailable) {
    if (geofence == null) return 'Menunggu data verifikasi sensor GPS...';
    if (geofence.isMocked) return 'Tombol terkunci karena terdeteksi Fake GPS.';
    if (!geofence.isInsideGeofence) {
      return 'Tombol terkunci: Anda belum berada di dalam radius 100m SPBN.';
    }
    if ((geofence.accuracy ?? 999) > AppConstants.maxAllowedGpsAccuracyMeters) {
      return 'Tombol terkunci: Akurasi sinyal GPS masih lemah.';
    }
    if (!isQuotaAvailable) return 'Tombol terkunci: Sisa kuota rekomendasi telah habis.';
    return 'Syarat pengambilan antrean belum terpenuhi.';
  }

  Widget _buildRequirementsStatusCard(
    BuildContext context,
    GeofenceSecurityState? geofence,
    bool isQuotaAvailable,
    bool hasActiveQueue,
  ) {
    final bool isInside = geofence?.isInsideGeofence ?? false;
    final bool isNotMocked = !(geofence?.isMocked ?? false);
    final bool isAccuracyGood = (geofence?.accuracy ?? 999) <= AppConstants.maxAllowedGpsAccuracyMeters;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.border),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Syarat Pengambilan Antrean Cerdas (Bab 3.3)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 14),
            _buildChecklistRow('Berada di dalam radius SPBN (<= 100m)', isInside),
            const SizedBox(height: 10),
            _buildChecklistRow('GPS Asli & Bebas Mock Location', isNotMocked),
            const SizedBox(height: 10),
            _buildChecklistRow('Akurasi Sinyal GPS Baik (<= 35m)', isAccuracyGood),
            const SizedBox(height: 10),
            _buildChecklistRow('Sisa Kuota Rekomendasi Tersedia', isQuotaAvailable),
            const SizedBox(height: 10),
            _buildChecklistRow('Tidak ada antrean yang sedang aktif', !hasActiveQueue),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistRow(String title, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: isSatisfied ? AppColors.success : AppColors.textMuted,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.normal,
              color: isSatisfied ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
