import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/repositories/mock_spbn_repository.dart';
import '../../../core/security/location_security_service.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/providers/auth_provider.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationAsync = ref.watch(spbnStationProvider);
    final letterAsync = ref.watch(recommendationLetterProvider);
    final shipAsync = ref.watch(activeShipProvider);
    final userAsync = ref.watch(fishermanProfileProvider);
    final geofenceState = ref.watch(geofenceSecurityNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userAsync.value?.name != null ? 'Halo, ${userAsync.value!.name}' : 'SPBN Madura',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                const Icon(Icons.location_pin, size: 12, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text(
                  stationAsync.value?.name ?? AppConstants.defaultSpbnName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Keluar Akun',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 22),
            onPressed: () {
              ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(spbnStationProvider);
          ref.invalidate(recommendationLetterProvider);
          ref.invalidate(activeShipProvider);
          await ref.read(geofenceSecurityNotifierProvider.notifier).refreshLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. KARTU STATUS OPERASIONAL SPBN
              _buildStationOperationalCard(context, stationAsync),

              const SizedBox(height: 16),

              // 2. RADAR & INDIKATOR GEOFENCING REALTIME
              _buildGeofenceRadarCard(context, ref, geofenceState),

              const SizedBox(height: 16),

              // 3. RINGKASAN KUOTA SOLAR BULANAN & MASA BERLAKU
              _buildQuotaAndShipCard(context, letterAsync, shipAsync),

              const SizedBox(height: 16),

              // 4. PANEL PENGUJIAN / DEMO SIMULASI GPS (UNTUK PENGUJIAN DOSEN)
              _buildDemoSimulationPanel(context, ref),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationOperationalCard(BuildContext context, AsyncValue stationAsync) {
    final station = stationAsync.value;
    final bool isOpen = station?.isOpen ?? true;
    final double stock = station?.stockLiters ?? 12500.0;
    final int queueCount = station?.activeQueueCount ?? 3;

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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_gas_station_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Status Operasional',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          isOpen ? 'Dermaga SPBN Buka' : 'SPBN Tutup Sementara',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOpen ? AppColors.textPrimary : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isOpen ? AppColors.successContainer : AppColors.dangerContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen ? AppColors.success : AppColors.danger,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOpen ? 'Melayani' : 'Tutup',
                        style: TextStyle(
                          color: isOpen ? AppColors.success : AppColors.danger,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14.0),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sisa Stok Solar Hari Ini',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.water_drop_rounded, size: 16, color: AppColors.accentSolar),
                          const SizedBox(width: 4),
                          Text(
                            AppFormatters.formatLiters(stock),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 36, color: AppColors.border),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Antrean di Dermaga',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.directions_boat_rounded, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text(
                            '$queueCount Kapal',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeofenceRadarCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<GeofenceSecurityState> geofenceAsync,
  ) {
    final state = geofenceAsync.value;
    final bool isInside = state?.isInsideGeofence ?? false;
    final bool isMocked = state?.isMocked ?? false;
    final double? distance = state?.distanceMeters;
    final double? accuracy = state?.accuracy;

    Color badgeColor;
    Color badgeContainer;
    String badgeText;
    IconData badgeIcon;

    if (isMocked) {
      badgeColor = AppColors.danger;
      badgeContainer = AppColors.dangerContainer;
      badgeText = 'PERINGATAN FAKE GPS';
      badgeIcon = Icons.warning_rounded;
    } else if (isInside) {
      badgeColor = AppColors.success;
      badgeContainer = AppColors.successContainer;
      badgeText = 'DALAM RADIUS SPBN (VALID)';
      badgeIcon = Icons.check_circle_rounded;
    } else {
      badgeColor = AppColors.danger;
      badgeContainer = AppColors.dangerContainer;
      badgeText = 'DI LUAR RADIUS SPBN';
      badgeIcon = Icons.cancel_rounded;
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isMocked ? AppColors.danger : (isInside ? AppColors.success : AppColors.border),
          width: isMocked || isInside ? 1.5 : 1.0,
        ),
      ),
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: badgeContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.radar_rounded, color: badgeColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar Geofencing GPS',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Batas Akses Pengambilan Antrean',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'Pindai Ulang Lokasi',
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.primary),
                  onPressed: () {
                    ref.read(geofenceSecurityNotifierProvider.notifier).refreshLocation();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Banner Status Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: badgeContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(badgeIcon, color: badgeColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Detail Metrik Spasial
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jarak ke SPBN', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          distance != null ? AppFormatters.formatDistance(distance) : 'Memindai...',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Maksimal ${AppConstants.defaultGeofenceRadiusMeters.toStringAsFixed(0)} m',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Akurasi Sinyal GPS', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                          accuracy != null ? '${accuracy.toStringAsFixed(1)} m' : 'Memindai...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: (accuracy ?? 99) <= AppConstants.maxAllowedGpsAccuracyMeters
                                ? AppColors.textPrimary
                                : AppColors.danger,
                          ),
                        ),
                        Text(
                          'Toleransi <= ${AppConstants.maxAllowedGpsAccuracyMeters.toStringAsFixed(0)} m',
                          style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            if (isMocked) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.danger),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.gpp_bad_rounded, color: AppColors.danger, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Peringatan Keamanan Lapis 1:\nTerdeteksi modul Fake GPS/Mock Location. Hak pengambilan antrean diblokir!',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.danger),
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

  Widget _buildQuotaAndShipCard(
    BuildContext context,
    AsyncValue letterAsync,
    AsyncValue shipAsync,
  ) {
    final letter = letterAsync.value;
    final ship = shipAsync.value;

    final double remaining = letter?.remainingQuota ?? 270.0;
    final double allocated = letter?.allocatedQuota ?? 450.0;
    final double usedRatio = allocated > 0 ? ((allocated - remaining) / allocated).clamp(0.0, 1.0) : 0.0;
    final int remainingDays = letter?.remainingDays ?? 70;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_boat_filled_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ship?.shipName ?? 'KM Mina Jaya',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        ),
                        Text(
                          'Mesin: ${ship?.enginePk.toStringAsFixed(0) ?? "15"} PK • Kapasitas: ${ship?.gtSize.toStringAsFixed(1) ?? "3.0"} GT',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$remainingDays Hari Lagi',
                    style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Progress Bar Kuota
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sisa Kuota Solar Rekomendasi',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                Text(
                  AppFormatters.formatQuota(remaining, allocated),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 1.0 - usedRatio, // Menampilkan porsi sisa kuota yang masih tersedia
                minHeight: 10,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  remaining > (allocated * 0.25) ? AppColors.secondary : AppColors.warning,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Terpakai: ${(usedRatio * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  'Sisa Kuota: ${((1.0 - usedRatio) * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSimulationPanel(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.4), width: 1.2),
      ),
      color: AppColors.infoContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.science_rounded, size: 20, color: AppColors.secondary),
                SizedBox(width: 8),
                Text(
                  'Simulasi Pengujian Black-Box (Uji Coba Lapangan)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Gunakan kontrol di bawah ini untuk mensimulasikan berbagai skenario GPS saat demontrasi ke dosen penguji:',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.location_on, size: 16, color: AppColors.success),
                  label: const Text('Dermaga SPBN (Valid 15m)'),
                  backgroundColor: AppColors.successContainer,
                  onPressed: () {
                    ref.read(geofenceSecurityNotifierProvider.notifier).simulateLocation(
                          latitude: AppConstants.defaultSpbnLatitude + 0.0001,
                          longitude: AppConstants.defaultSpbnLongitude + 0.0001,
                          isMocked: false,
                          accuracy: 8.0,
                        );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.wrong_location_outlined, size: 16, color: AppColors.danger),
                  label: const Text('Luar Radius (550m)'),
                  backgroundColor: AppColors.dangerContainer,
                  onPressed: () {
                    ref.read(geofenceSecurityNotifierProvider.notifier).simulateLocation(
                          latitude: AppConstants.defaultSpbnLatitude + 0.005,
                          longitude: AppConstants.defaultSpbnLongitude,
                          isMocked: false,
                          accuracy: 12.0,
                        );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.gpp_bad, size: 16, color: AppColors.danger),
                  label: const Text('Uji Fake GPS (Mock)'),
                  backgroundColor: AppColors.dangerContainer,
                  onPressed: () {
                    ref.read(geofenceSecurityNotifierProvider.notifier).simulateLocation(
                          latitude: AppConstants.defaultSpbnLatitude,
                          longitude: AppConstants.defaultSpbnLongitude,
                          isMocked: true,
                          accuracy: 5.0,
                        );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
