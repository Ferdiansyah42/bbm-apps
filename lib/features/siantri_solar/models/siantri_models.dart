import 'dart:convert';

/// Konfigurasi Kapasitas Mesin Kapal & Kuota Maksimal Solar Subsidi Nelayan SPBN
class BoatEngineTier {
  final String id;
  final String name; // Contoh: Mesin 15 PK
  final String label; // Contoh: Mesin 15 PK - Maks. 45 Liter
  final double maxQuotaLiters;
  final String description;

  const BoatEngineTier({
    required this.id,
    required this.name,
    required this.label,
    required this.maxQuotaLiters,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoatEngineTier &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Alias kompatibilitas
typedef VehicleTypeConfig = BoatEngineTier;

const List<BoatEngineTier> kBoatEngineTiers = [
  BoatEngineTier(
    id: 'pk_10',
    name: 'Mesin 10 PK',
    label: 'Mesin 10 PK - Maks. 30 Liter',
    maxQuotaLiters: 30.0,
    description: 'Perahu Jukung / Motor Tempel 10 PK (Nelayan Kecil)',
  ),
  BoatEngineTier(
    id: 'pk_15',
    name: 'Mesin 15 PK',
    label: 'Mesin 15 PK - Maks. 45 Liter',
    maxQuotaLiters: 45.0,
    description: 'Perahu Motor 15 PK / Mesin Dongfeng (Nelayan Tradisional)',
  ),
  BoatEngineTier(
    id: 'pk_24',
    name: 'Mesin 24 PK',
    label: 'Mesin 24 PK - Maks. 60 Liter',
    maxQuotaLiters: 60.0,
    description: 'Kapal Nelayan 24 PK / <5 GT (Nelayan Menengah)',
  ),
  BoatEngineTier(
    id: 'pk_30',
    name: 'Mesin 30 PK',
    label: 'Mesin 30 PK - Maks. 80 Liter',
    maxQuotaLiters: 80.0,
    description: 'Kapal Gillnet / Purse Seine Kecil 30 PK (Maks 80 L)',
  ),
];

/// Kompatibilitas backwards
const List<BoatEngineTier> kVehicleTypes = kBoatEngineTiers;

/// Model Tiket Antrean Digital SiAntri Solar Nelayan (Boarding Pass)
class SiAntriTicket {
  final String queueNumber; // format: SLR-00X
  final String fishermanName; // Nama Nelayan
  final String recommendationNumber; // Nomor Surat Rekomendasi / Barcode DKP
  final BoatEngineTier engineTier; // Kapasitas Mesin Kapal & Kuota
  final double requestedLiters; // Liter solar yang diminta
  final DateTime estimatedTime; // Estimasi jam pengisian
  final String qrData;
  final DateTime createdAt;
  final String status; // 'WAITING', 'SERVING', 'COMPLETED'

  const SiAntriTicket({
    required this.queueNumber,
    required this.fishermanName,
    required this.recommendationNumber,
    required this.engineTier,
    required this.requestedLiters,
    required this.estimatedTime,
    required this.qrData,
    required this.createdAt,
    this.status = 'WAITING',
  });

  // Getter kompatibilitas
  String get driverName => fishermanName;
  String get plateNumber => recommendationNumber;
  BoatEngineTier get vehicleType => engineTier;

  Map<String, dynamic> toQrPayload() {
    return {
      'app': 'SiAntri Solar Nelayan SPBN Madura',
      'queue_code': queueNumber,
      'recommendation_number': recommendationNumber,
      'fisherman_name': fishermanName,
      'engine_capacity': engineTier.name,
      'requested_liters': requestedLiters,
      'est_time': estimatedTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'status': status,
    };
  }

  String encodeQr() => jsonEncode(toQrPayload());
}

/// Model Item Antrean Live SPBN (FIFO)
class LiveQueueItem {
  final String queueNumber; // format: SLR-00X
  final String recommendationNumber; // Nomor Surat Rekomendasi
  final String fishermanName; // Nama Nelayan
  final String engineName; // Contoh: Mesin 15 PK
  final double liters;
  final String status; // 'SERVING' (Sedang Dilayani) atau 'WAITING' (Menunggu)
  final String estimatedWaitTime;

  const LiveQueueItem({
    required this.queueNumber,
    required this.recommendationNumber,
    required this.fishermanName,
    required this.engineName,
    required this.liters,
    required this.status,
    required this.estimatedWaitTime,
  });

  // Getter kompatibilitas
  String get plateNumber => recommendationNumber;
  String get driverName => fishermanName;
  String get vehicleName => engineName;

  bool get isServing => status.toUpperCase() == 'SERVING';
  bool get isWaiting => status.toUpperCase() == 'WAITING';

  String get qrData =>
      'SIANTRI-SPBN-MADURA:$queueNumber:$recommendationNumber:${liters.toInt()}';
}
