import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/siantri_models.dart';

class SiAntriState {
  final double tankStockLiters;
  final bool isAvailable;
  final bool isInsideGeofence;
  final double currentDistanceMeters;
  final SiAntriTicket? currentTicket;
  final List<LiveQueueItem> liveQueues;
  final int nextQueueNumber;

  const SiAntriState({
    required this.tankStockLiters,
    required this.isAvailable,
    required this.isInsideGeofence,
    required this.currentDistanceMeters,
    this.currentTicket,
    required this.liveQueues,
    required this.nextQueueNumber,
  });

  int get activeQueueCount => liveQueues.length;

  SiAntriState copyWith({
    double? tankStockLiters,
    bool? isAvailable,
    bool? isInsideGeofence,
    double? currentDistanceMeters,
    SiAntriTicket? currentTicket,
    bool clearTicket = false,
    List<LiveQueueItem>? liveQueues,
    int? nextQueueNumber,
  }) {
    return SiAntriState(
      tankStockLiters: tankStockLiters ?? this.tankStockLiters,
      isAvailable: isAvailable ?? this.isAvailable,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
      currentDistanceMeters: currentDistanceMeters ?? this.currentDistanceMeters,
      currentTicket: clearTicket ? null : (currentTicket ?? this.currentTicket),
      liveQueues: liveQueues ?? this.liveQueues,
      nextQueueNumber: nextQueueNumber ?? this.nextQueueNumber,
    );
  }

  factory SiAntriState.initial() {
    return SiAntriState(
      tankStockLiters: 14250.0,
      isAvailable: true,
      isInsideGeofence: true, // Default true agar tombol siap digunakan di awal
      currentDistanceMeters: 25.0,
      currentTicket: null,
      nextQueueNumber: 4,
      liveQueues: const [
        LiveQueueItem(
          queueNumber: 'SLR-001',
          plateNumber: 'M 1892 AB',
          driverName: 'Pak Halim',
          vehicleName: 'Truk Roda 6 / Angkutan Barang',
          liters: 80.0,
          status: 'SERVING',
          estimatedWaitTime: 'Sedang Mengisi',
        ),
        LiveQueueItem(
          queueNumber: 'SLR-002',
          plateNumber: 'M 8234 CA',
          driverName: 'Pak Rusdi',
          vehicleName: 'Roda 4 Angkutan Umum / Barang',
          liters: 50.0,
          status: 'WAITING',
          estimatedWaitTime: '~5 Menit',
        ),
        LiveQueueItem(
          queueNumber: 'SLR-003',
          plateNumber: 'M 4120 WP',
          driverName: 'Pak Samsul',
          vehicleName: 'Bus / Angkutan Penumpang Besar',
          liters: 100.0,
          status: 'WAITING',
          estimatedWaitTime: '~12 Menit',
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
  void setGeofenceStatus(bool isInside, double distance) {
    state = state.copyWith(
      isInsideGeofence: isInside,
      currentDistanceMeters: distance,
    );
  }

  /// Pendaftaran antrean dan pembuatan tiket QR Code
  SiAntriTicket registerQueue({
    required String driverName,
    required String plateNumber,
    required VehicleTypeConfig vehicleType,
    required double requestedLiters,
  }) {
    final queueNumberStr = 'SLR-${state.nextQueueNumber.toString().padLeft(3, '0')}';
    final now = DateTime.now();
    // Estimasi kedatangan berdasarkan urutan antrean (~6 menit per kendaraan)
    final waitingCount = state.liveQueues.where((q) => q.isWaiting).length;
    final estimatedMinutes = 5 + (waitingCount * 6);
    final estimatedTime = now.add(Duration(minutes: estimatedMinutes));

    final newTicket = SiAntriTicket(
      queueNumber: queueNumberStr,
      driverName: driverName.trim(),
      plateNumber: plateNumber.trim().toUpperCase(),
      vehicleType: vehicleType,
      requestedLiters: requestedLiters,
      estimatedTime: estimatedTime,
      qrData: 'SIANTRI-SPBU-MADURA:$queueNumberStr:${plateNumber.trim().toUpperCase()}:${requestedLiters.toInt()}',
      createdAt: now,
      status: 'WAITING',
    );

    final updatedQueues = List<LiveQueueItem>.from(state.liveQueues)
      ..add(
        LiveQueueItem(
          queueNumber: queueNumberStr,
          plateNumber: plateNumber.trim().toUpperCase(),
          driverName: driverName.trim(),
          vehicleName: vehicleType.name,
          liters: requestedLiters,
          status: 'WAITING',
          estimatedWaitTime: '~$estimatedMinutes Menit',
        ),
      );

    state = state.copyWith(
      currentTicket: newTicket,
      liveQueues: updatedQueues,
      nextQueueNumber: state.nextQueueNumber + 1,
      tankStockLiters: (state.tankStockLiters - requestedLiters).clamp(0.0, 999999.0),
    );

    return newTicket;
  }

  /// Membatalkan tiket yang sedang aktif
  void cancelTicket() {
    if (state.currentTicket == null) return;
    final ticketCode = state.currentTicket!.queueNumber;
    final updatedQueues = state.liveQueues.where((q) => q.queueNumber != ticketCode).toList();

    state = state.copyWith(
      clearTicket: true,
      liveQueues: updatedQueues,
    );
  }
}

final siAntriProvider = NotifierProvider<SiAntriNotifier, SiAntriState>(
  SiAntriNotifier.new,
);
