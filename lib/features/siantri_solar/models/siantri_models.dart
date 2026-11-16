import 'dart:convert';

/// Konfigurasi tipe kendaraan dan kuota maksimal harian solar subsidi
class VehicleTypeConfig {
  final String id;
  final String name;
  final String description;
  final double maxQuotaLiters;

  const VehicleTypeConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.maxQuotaLiters,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleTypeConfig &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const List<VehicleTypeConfig> kVehicleTypes = [
  VehicleTypeConfig(
    id: 'r4_pribadi',
    name: 'Mobil Pribadi Roda 4',
    description: 'Kendaraan pribadi / SUV / MPV (Maks 40 L)',
    maxQuotaLiters: 40.0,
  ),
  VehicleTypeConfig(
    id: 'r4_angkutan',
    name: 'Roda 4 Angkutan Umum / Barang',
    description: 'Pickup / Angkutan barang kecil (Maks 60 L)',
    maxQuotaLiters: 60.0,
  ),
  VehicleTypeConfig(
    id: 'truk_r6',
    name: 'Truk Roda 6 / Angkutan Barang',
    description: 'Truk Roda 6 / Angkutan Logistik (Maks 80 L)',
    maxQuotaLiters: 80.0,
  ),
  VehicleTypeConfig(
    id: 'bus_besar',
    name: 'Bus / Angkutan Penumpang Besar',
    description: 'Bus sedang & besar antar kota (Maks 100 L)',
    maxQuotaLiters: 100.0,
  ),
];

/// Model Tiket Antrean Digital SiAntri Solar
class SiAntriTicket {
  final String queueNumber; // format: SLR-00X
  final String driverName;
  final String plateNumber; // Seri Madura 'M'
  final VehicleTypeConfig vehicleType;
  final double requestedLiters;
  final DateTime estimatedTime;
  final String qrData;
  final DateTime createdAt;
  final String status; // 'WAITING', 'SERVING', 'COMPLETED'

  const SiAntriTicket({
    required this.queueNumber,
    required this.driverName,
    required this.plateNumber,
    required this.vehicleType,
    required this.requestedLiters,
    required this.estimatedTime,
    required this.qrData,
    required this.createdAt,
    this.status = 'WAITING',
  });

  Map<String, dynamic> toQrPayload() {
    return {
      'app': 'SiAntri Solar SPBU Madura',
      'queue_code': queueNumber,
      'driver': driverName,
      'plate': plateNumber,
      'vehicle': vehicleType.name,
      'liters': requestedLiters,
      'est_time': estimatedTime.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  String encodeQr() => jsonEncode(toQrPayload());
}

/// Model Item Antrean Live (FIFO)
class LiveQueueItem {
  final String queueNumber;
  final String plateNumber;
  final String driverName;
  final String vehicleName;
  final double liters;
  final String status; // 'SERVING' (Sedang Dilayani) atau 'WAITING' (Menunggu)
  final String estimatedWaitTime;

  const LiveQueueItem({
    required this.queueNumber,
    required this.plateNumber,
    required this.driverName,
    required this.vehicleName,
    required this.liters,
    required this.status,
    required this.estimatedWaitTime,
  });

  bool get isServing => status.toUpperCase() == 'SERVING';
  bool get isWaiting => status.toUpperCase() == 'WAITING';
}
