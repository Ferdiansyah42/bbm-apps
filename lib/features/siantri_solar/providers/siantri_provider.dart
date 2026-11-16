import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../settings/models/spbn_settings.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/siantri_models.dart';

class SiAntriState {
  final double tankStockLiters;
  final double tankCapacityLiters;
  final bool isAvailable;
  final bool isInsideGeofence;
  final bool isMockLocation;
  final double currentDistanceMeters;
  final SiAntriTicket? currentTicket;
  final List<LiveQueueItem> liveQueues;
  final int nextQueueNumber;

  const SiAntriState({
    required this.tankStockLiters,
    this.tankCapacityLiters = 8000.0,
    required this.isAvailable,
    required this.isInsideGeofence,
    this.isMockLocation = false,
    required this.currentDistanceMeters,
    this.currentTicket,
    required this.liveQueues,
    required this.nextQueueNumber,
  });

  int get activeQueueCount => liveQueues.length;
  double get tankPercentage =>
      (tankStockLiters / tankCapacityLiters).clamp(0.0, 1.0);

  /// Menentukan apakah tombol pendaftaran antrean dapat ditekan berdasarkan
  /// status saklar Geofence di Pengaturan (Bypass mode saat OFF)
  bool canRegister(SpbnSettings settings) {
    if (!isAvailable) return false;
    // Jika Mode Bebas Uji (Geofencing Dinonaktifkan), tombol selalu aktif
    if (!settings.isGeofenceEnabled) {
      return true;
    }
    // Jika Geofencing Aktif, harus berada dalam radius dan bukan Fake GPS
    return isInsideGeofence && !isMockLocation;
  }

  SiAntriState copyWith({
    double? tankStockLiters,
    double? tankCapacityLiters,
    bool? isAvailable,
    bool? isInsideGeofence,
    bool? isMockLocation,
    double? currentDistanceMeters,
    SiAntriTicket? currentTicket,
    bool clearTicket = false,
    List<LiveQueueItem>? liveQueues,
    int? nextQueueNumber,
  }) {
    return SiAntriState(
      tankStockLiters: tankStockLiters ?? this.tankStockLiters,
      tankCapacityLiters: tankCapacityLiters ?? this.tankCapacityLiters,
      isAvailable: isAvailable ?? this.isAvailable,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      currentDistanceMeters: currentDistanceMeters ?? this.currentDistanceMeters,
      currentTicket: clearTicket ? null : (currentTicket ?? this.currentTicket),
      liveQueues: liveQueues ?? this.liveQueues,
      nextQueueNumber: nextQueueNumber ?? this.nextQueueNumber,
    );
  }

  factory SiAntriState.initial() {
    return const SiAntriState(
      tankStockLiters: 4250.0, // 4.250 L dari 8.000 L kapasitas
      tankCapacityLiters: 8000.0,
      isAvailable: true,
      isInsideGeofence: true,
      isMockLocation: false,
      currentDistanceMeters: 38.0,
      currentTicket: null,
      nextQueueNumber: 2, // Tiket berikutnya adalah SLR-002
      liveQueues: [
        LiveQueueItem(
          queueNumber: 'SLR-001',
          recommendationNumber: 'REK-DKP-2026-001',
          fishermanName: 'Pak Achmad Zaini',
          engineName: 'Mesin 15 PK',
          liters: 45.0,
          status: 'SERVING',
          estimatedWaitTime: 'Sedang Dilayani',
        ),
      ],
    );
  }
}

class SiAntriNotifier extends Notifier<SiAntriState> {
  @override
  SiAntriState build() {
    return SiAntriState.initial();
  }

  /// Toggle / Set status simulasi geofence
  void setGeofenceStatus({
    required bool isInside,
    required double distance,
    bool isMock = false,
  }) {
    state = state.copyWith(
      isInsideGeofence: isInside,
      currentDistanceMeters: distance,
      isMockLocation: isMock,
    );
  }

  /// Pendaftaran antrean dan penerbitan tiket QR Nelayan
  SiAntriTicket registerQueue({
    String? fishermanName,
    String? recommendationNumber,
    BoatEngineTier? engineTier,
    required double requestedLiters,
    // Parameter kompatibilitas
    String? driverName,
    String? plateNumber,
    BoatEngineTier? vehicleType,
  }) {
    final finalFisherman = (fishermanName ?? driverName ?? 'Nelayan').trim();
    final finalRecommendation =
        (recommendationNumber ?? plateNumber ?? 'REK-DKP-2026-084').trim().toUpperCase();
    final finalTier = engineTier ?? vehicleType ?? kBoatEngineTiers[1];

    final queueNumberStr =
        'SLR-${state.nextQueueNumber.toString().padLeft(3, '0')}';
    final now = DateTime.now();

    // Estimasi kedatangan berdasarkan urutan antrean (~8 menit per kapal)
    final waitingCount = state.liveQueues.where((q) => q.isWaiting).length;
    final estimatedMinutes = 8 + (waitingCount * 8);
    final estimatedTime = now.add(Duration(minutes: estimatedMinutes));

    final newTicket = SiAntriTicket(
      queueNumber: queueNumberStr,
      fishermanName: finalFisherman,
      recommendationNumber: finalRecommendation,
      engineTier: finalTier,
      requestedLiters: requestedLiters,
      estimatedTime: estimatedTime,
      qrData:
          'SIANTRI-SPBN-MADURA:$queueNumberStr:$finalRecommendation:${requestedLiters.toInt()}',
      createdAt: now,
      status: 'WAITING',
    );

    final updatedQueues = List<LiveQueueItem>.from(state.liveQueues)
      ..add(
        LiveQueueItem(
          queueNumber: queueNumberStr,
          recommendationNumber: finalRecommendation,
          fishermanName: finalFisherman,
          engineName: finalTier.name,
          liters: requestedLiters,
          status: 'WAITING',
          estimatedWaitTime: '~$estimatedMinutes Menit',
        ),
      );

    state = state.copyWith(
      currentTicket: newTicket,
      liveQueues: updatedQueues,
      nextQueueNumber: state.nextQueueNumber + 1,
      tankStockLiters:
          (state.tankStockLiters - requestedLiters).clamp(0.0, state.tankCapacityLiters),
    );

    return newTicket;
  }

  /// Membatalkan tiket yang sedang aktif
  void cancelTicket() {
    if (state.currentTicket == null) return;
    final ticketCode = state.currentTicket!.queueNumber;
    final updatedQueues =
        state.liveQueues.where((q) => q.queueNumber != ticketCode).toList();

    state = state.copyWith(
      clearTicket: true,
      liveQueues: updatedQueues,
    );
  }
}

final siAntriProvider = NotifierProvider<SiAntriNotifier, SiAntriState>(
  SiAntriNotifier.new,
);

/// Provider global untuk memegang tiket antrean nelayan aktif saat ini
class ActiveTicketNotifier extends Notifier<SiAntriTicket?> {
  @override
  SiAntriTicket? build() {
    // Sinkronkan dengan currentTicket di siAntriProvider
    return ref.watch(siAntriProvider.select((s) => s.currentTicket));
  }

  void setTicket(SiAntriTicket ticket) {
    state = ticket;
  }

  void clearTicket() {
    state = null;
    ref.read(siAntriProvider.notifier).cancelTicket();
  }
}

final activeTicketProvider =
    NotifierProvider<ActiveTicketNotifier, SiAntriTicket?>(
  ActiveTicketNotifier.new,
);

