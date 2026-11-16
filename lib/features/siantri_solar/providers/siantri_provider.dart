import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/models/spbn_settings.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/siantri_models.dart';

class SiAntriState {
  final double tankStockLiters;
  final double tankCapacityLiters;
  final bool isAvailable;
  final SolarAvailabilityStatus solarStatus;
  final bool isInsideGeofence;
  final bool isMockLocation;
  final double currentDistanceMeters;
  final SiAntriTicket? currentTicket;
  final List<LiveQueueItem> liveQueues;
  final List<CompletedTransaction> completedTransactions;
  final int nextQueueNumber;

  const SiAntriState({
    required this.tankStockLiters,
    this.tankCapacityLiters = 8000.0,
    required this.isAvailable,
    this.solarStatus = SolarAvailabilityStatus.available,
    required this.isInsideGeofence,
    this.isMockLocation = false,
    required this.currentDistanceMeters,
    this.currentTicket,
    required this.liveQueues,
    this.completedTransactions = const [],
    required this.nextQueueNumber,
  });

  int get activeQueueCount =>
      liveQueues.where((q) => q.isServing || q.isWaiting).length;

  int get waitingQueueCount => liveQueues.where((q) => q.isWaiting).length;

  LiveQueueItem? get currentServingQueue {
    for (final q in liveQueues) {
      if (q.isServing) return q;
    }
    for (final q in liveQueues) {
      if (q.isWaiting) return q;
    }
    return null;
  }

  double get totalLitersDispensedToday =>
      completedTransactions.fold(0.0, (sum, tx) => sum + tx.liters);

  double get tankPercentage =>
      (tankStockLiters / tankCapacityLiters).clamp(0.0, 1.0);

  /// Menentukan apakah tombol pendaftaran antrean dapat ditekan berdasarkan
  /// status saklar Geofence di Pengaturan (Bypass mode saat OFF)
  bool canRegister(SpbnSettings settings) {
    if (!isAvailable || solarStatus == SolarAvailabilityStatus.empty) return false;
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
    SolarAvailabilityStatus? solarStatus,
    bool? isInsideGeofence,
    bool? isMockLocation,
    double? currentDistanceMeters,
    SiAntriTicket? currentTicket,
    bool clearTicket = false,
    List<LiveQueueItem>? liveQueues,
    List<CompletedTransaction>? completedTransactions,
    int? nextQueueNumber,
  }) {
    return SiAntriState(
      tankStockLiters: tankStockLiters ?? this.tankStockLiters,
      tankCapacityLiters: tankCapacityLiters ?? this.tankCapacityLiters,
      isAvailable: isAvailable ?? this.isAvailable,
      solarStatus: solarStatus ?? this.solarStatus,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      isMockLocation: isMockLocation ?? this.isMockLocation,
      currentDistanceMeters: currentDistanceMeters ?? this.currentDistanceMeters,
      currentTicket: clearTicket ? null : (currentTicket ?? this.currentTicket),
      liveQueues: liveQueues ?? this.liveQueues,
      completedTransactions:
          completedTransactions ?? this.completedTransactions,
      nextQueueNumber: nextQueueNumber ?? this.nextQueueNumber,
    );
  }

  factory SiAntriState.initial() {
    return SiAntriState(
      tankStockLiters: 4250.0, // 4.250 L dari 8.000 L kapasitas
      tankCapacityLiters: 8000.0,
      isAvailable: true,
      solarStatus: SolarAvailabilityStatus.available,
      isInsideGeofence: true,
      isMockLocation: false,
      currentDistanceMeters: 38.0,
      currentTicket: null,
      nextQueueNumber: 2, // Tiket berikutnya adalah SLR-002
      liveQueues: const [
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
      completedTransactions: [
        CompletedTransaction(
          id: 'TX-INIT-001',
          queueNumber: 'SLR-000',
          fishermanName: 'H. Abdul Wahid',
          recommendationNumber: 'REK-DKP-2026-000',
          engineName: 'Mesin 24 PK',
          liters: 60.0,
          completedAt: DateTime(2026, 11, 16, 7, 30),
          notes: 'Pengisian reguler pagi hari di dermaga',
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

  /// OPERATOR: Selesaikan pengisian dispenser saat ini
  CompletedTransaction? completeCurrentServing() {
    final serving = state.currentServingQueue;
    if (serving == null) return null;

    final now = DateTime.now();
    final completedTx = CompletedTransaction(
      id: 'TX-${now.millisecondsSinceEpoch}',
      queueNumber: serving.queueNumber,
      fishermanName: serving.fishermanName,
      recommendationNumber: serving.recommendationNumber,
      engineName: serving.engineName,
      liters: serving.liters,
      completedAt: now,
      notes: 'Terverifikasi selesai oleh operator SPBN',
    );

    // Hapus tiket yang sudah selesai dari liveQueues
    final remainingQueues = state.liveQueues
        .where((q) => q.queueNumber != serving.queueNumber)
        .toList();

    // Majukan antrean berikutnya menjadi 'SERVING' jika ada yang sedang 'WAITING'
    if (remainingQueues.isNotEmpty) {
      final firstWaitingIndex =
          remainingQueues.indexWhere((q) => q.isWaiting || q.isServing);
      if (firstWaitingIndex != -1) {
        final nextItem = remainingQueues[firstWaitingIndex];
        remainingQueues[firstWaitingIndex] = nextItem.copyWith(
          status: 'SERVING',
          estimatedWaitTime: 'Sedang Dilayani',
        );
      }
    }

    final newHistory = [completedTx, ...state.completedTransactions];

    // Jika tiket nelayan aktif saat ini adalah yang diselesaikan
    final isMyTicketCompleted =
        state.currentTicket?.queueNumber == serving.queueNumber;

    state = state.copyWith(
      liveQueues: remainingQueues,
      completedTransactions: newHistory,
      clearTicket: isMyTicketCompleted,
    );

    return completedTx;
  }

  /// OPERATOR: Lewati antrean (misal nelayan tidak hadir di dermaga)
  LiveQueueItem? skipCurrentServing() {
    final serving = state.currentServingQueue;
    if (serving == null) return null;

    final remainingQueues = state.liveQueues
        .where((q) => q.queueNumber != serving.queueNumber)
        .toList();

    // Majukan antrean berikutnya
    if (remainingQueues.isNotEmpty) {
      final firstWaitingIndex =
          remainingQueues.indexWhere((q) => q.isWaiting || q.isServing);
      if (firstWaitingIndex != -1) {
        final nextItem = remainingQueues[firstWaitingIndex];
        remainingQueues[firstWaitingIndex] = nextItem.copyWith(
          status: 'SERVING',
          estimatedWaitTime: 'Sedang Dilayani',
        );
      }
    }

    final isMyTicketSkipped =
        state.currentTicket?.queueNumber == serving.queueNumber;

    state = state.copyWith(
      liveQueues: remainingQueues,
      clearTicket: isMyTicketSkipped,
    );

    return serving;
  }

  /// OPERATOR: Mengubah status ketersediaan solar
  void setSolarStatus(SolarAvailabilityStatus newStatus) {
    state = state.copyWith(
      solarStatus: newStatus,
      isAvailable: newStatus != SolarAvailabilityStatus.empty,
    );
  }

  /// OPERATOR: Menambah stok tangki (Bongkar tangki tanker BBM)
  void addTankStock(double liters) {
    final newStock =
        (state.tankStockLiters + liters).clamp(0.0, state.tankCapacityLiters);
    state = state.copyWith(
      tankStockLiters: newStock,
      isAvailable: true,
      solarStatus: SolarAvailabilityStatus.available,
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

/// Provider peran aktif: Mode Nelayan vs Mode Operator SPBN
class AppRoleNotifier extends Notifier<UserRole> {
  @override
  UserRole build() {
    final auth = ref.watch(authNotifierProvider);
    if (auth.currentUser?.isOperator == true) {
      return UserRole.operator;
    }
    return UserRole.fisherman;
  }

  void setRole(UserRole role) {
    state = role;
  }

  void toggleRole() {
    state = state == UserRole.fisherman ? UserRole.operator : UserRole.fisherman;
  }
}

final appRoleProvider = NotifierProvider<AppRoleNotifier, UserRole>(
  AppRoleNotifier.new,
);
