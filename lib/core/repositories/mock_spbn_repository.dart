import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../models/models.dart';
import '../utils/haversine_calculator.dart';
import 'remote_spbn_repository.dart';
import 'spbn_repository.dart';

/// Exception khusus jika posisi berada di luar radius SPBN (default 100 meter)
class OutsideGeofenceException implements Exception {
  final double distanceMeters;
  const OutsideGeofenceException(this.distanceMeters);

  @override
  String toString() =>
      'Anda berada di luar radius SPBN (${distanceMeters.toStringAsFixed(1)} m > ${AppConstants.defaultGeofenceRadiusMeters} m). Silakan mendekat ke area dermaga SPBN.';
}

/// Exception jika terdeteksi Fake GPS / Mock Location
class MockLocationDetectedException implements Exception {
  const MockLocationDetectedException();

  @override
  String toString() =>
      'Aplikasi Fake GPS/Mock Location terdeteksi! Pengambilan antrean diblokir demi keamanan.';
}

/// Exception jika akurasi GPS terlalu rendah (accuracy > 35 meter)
class GpsAccuracyTooLowException implements Exception {
  final double accuracy;
  const GpsAccuracyTooLowException(this.accuracy);

  @override
  String toString() =>
      'Akurasi sinyal GPS lemah (${accuracy.toStringAsFixed(1)} m > ${AppConstants.maxAllowedGpsAccuracyMeters} m). Harap berada di ruang terbuka dermaga.';
}

/// Exception jika nelayan sudah memiliki antrean aktif
class ActiveQueueExistsException implements Exception {
  final String activeQueueCode;
  const ActiveQueueExistsException(this.activeQueueCode);

  @override
  String toString() => 'Anda sudah memiliki antrean aktif dengan kode $activeQueueCode.';
}

/// Exception jika kuota solar rekomendasi telah habis
class QuotaExhaustedException implements Exception {
  const QuotaExhaustedException();

  @override
  String toString() => 'Sisa kuota surat rekomendasi Anda telah habis atau kedaluwarsa.';
}

/// Implementasi Mock Repository untuk simulasi operasional SPBN Madura.
/// Memungkinkan demo langsung ke dosen tanpa backend Laravel / FastAPI.
class MockSpbnRepository implements SpbnRepository {
  // Simulasi data profil nelayan
  FishermanUser _mockUser = const FishermanUser(
    id: 1,
    name: 'Achmad Zaini',
    nik: '3528011204850002',
    phone: '081234567890',
    role: 'fisherman',
    fishermanTier: 'small', // Nelayan tradisional <= 5 GT
    fcmToken: 'fcm_mock_token_madura_001',
  );

  // Simulasi kapal nelayan: KM Mina Jaya 15 PK
  final Ship _mockShip = const Ship(
    id: 1,
    userId: 1,
    shipName: 'KM Mina Jaya',
    gtSize: 3.0, // 3 GT
    enginePk: 15.0, // 15 PK
    dailyNeedEst: 35.0, // 35 Liter per trip
    isActive: true,
  );

  // Simulasi surat rekomendasi DKP: Alokasi 450 L, sisa 270 L
  RecommendationLetter _mockLetter = RecommendationLetter(
    id: 1,
    shipId: 1,
    barcodeNumber: 'REK-DKP-2026-MADURA-001',
    allocatedQuota: 450.0,
    remainingQuota: 270.0,
    validFrom: DateTime.now().subtract(const Duration(days: 20)),
    validUntil: DateTime.now().add(const Duration(days: 70)), // 3 bulan berlaku
    status: 'ACTIVE',
  );

  // Simulasi SPBN Madura: SPBN Pelabuhan Branta Pamekasan
  SpbnStation _mockStation = const SpbnStation(
    id: 1,
    name: AppConstants.defaultSpbnName,
    latitude: AppConstants.defaultSpbnLatitude,
    longitude: AppConstants.defaultSpbnLongitude,
    radiusMeters: AppConstants.defaultGeofenceRadiusMeters,
    stockLiters: 12500.0,
    isOpen: true,
    activeQueueCount: 3,
  );

  // Status tiket antrean aktif nelayan (awalnya null, terbit setelah takePriorityQueue)
  QueueTicket? _activeTicket;

  // Riwayat transaksi pengisian solar (termasuk contoh anomali dari Blueprint Bab 6.1)
  final List<TransactionHistory> _mockTransactions = [
    TransactionHistory(
      id: 101,
      queueId: 88,
      spbnId: 1,
      shipId: 1,
      letterId: 1,
      officerId: 3,
      transactionRef: 'TRX-20261114-0041',
      volumeLiters: 35.0,
      anomalyScore: 0.12,
      isAnomaly: false,
      anomalyReasons: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 3)),
    ),
    TransactionHistory(
      id: 100,
      queueId: 81,
      spbnId: 1,
      shipId: 1,
      letterId: 1,
      officerId: 3,
      transactionRef: 'TRX-20261111-0028',
      volumeLiters: 40.0,
      anomalyScore: 0.18,
      isAnomaly: false,
      anomalyReasons: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 5, hours: 6)),
    ),
    TransactionHistory(
      id: 99,
      queueId: 74,
      spbnId: 1,
      shipId: 1,
      letterId: 1,
      officerId: 2,
      transactionRef: 'TRX-20261108-0015',
      volumeLiters: 35.0,
      anomalyScore: 0.08,
      isAnomaly: false,
      anomalyReasons: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 8, hours: 2)),
    ),
    // Contoh transaksi terdeteksi anomali sesuai spesifikasi Blueprint Tabel 3 & Bab 6.1
    TransactionHistory(
      id: 98,
      queueId: 65,
      spbnId: 1,
      shipId: 1,
      letterId: 1,
      officerId: 1,
      transactionRef: 'TRX-20261106-0092',
      volumeLiters: 70.0,
      anomalyScore: 0.86,
      isAnomaly: true,
      anomalyReasons: const [
        'Frekuensi pembelian tinggi: 3 transaksi dalam 24 jam terakhir.',
        'Jeda antar-pembelian terlalu singkat (1.5 jam).',
        'Volume melebihi estimasi kebutuhan harian mesin (rasio 2.0x).',
      ],
      createdAt: DateTime.now().subtract(const Duration(days: 10, hours: 5)),
    ),
  ];

  @override
  Future<FishermanUser> login(String identifier, {String? fcmToken}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    _mockUser = _mockUser.copyWith(
      nik: identifier,
      fcmToken: fcmToken ?? _mockUser.fcmToken,
    );
    return _mockUser;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<FishermanUser> getFishermanProfile() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockUser;
  }

  @override
  Future<Ship> getActiveShip() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockShip;
  }

  @override
  Future<RecommendationLetter> getRecommendationLetter() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockLetter;
  }

  @override
  Future<SpbnStation> getSpbnStation() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _mockStation;
  }

  @override
  Future<QueueTicket?> getActiveQueue() async {
    await Future.delayed(const Duration(milliseconds: 150));
    return _activeTicket;
  }

  @override
  Future<List<TransactionHistory>> getTransactionHistories() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_mockTransactions);
  }

  @override
  Future<QueueTicket> takePriorityQueue({
    required double userLat,
    required double userLon,
    required bool isMocked,
    required double accuracy,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // 1. Anti-Mock GPS check (Blueprint Bab 3.3)
    if (isMocked) {
      throw const MockLocationDetectedException();
    }

    // 2. Akurasi sinyal GPS check (accuracy <= 35m)
    if (accuracy > AppConstants.maxAllowedGpsAccuracyMeters) {
      throw GpsAccuracyTooLowException(accuracy);
    }

    // 3. Geofence distance check (Haversine Formula <= 100m)
    final double distance = HaversineCalculator.calculateDistance(
      lat1: userLat,
      lon1: userLon,
      lat2: _mockStation.latitude,
      lon2: _mockStation.longitude,
    );

    if (distance > _mockStation.radiusMeters) {
      throw OutsideGeofenceException(distance);
    }

    // 4. Validasi kuota rekomendasi
    if (!_mockLetter.isQuotaAvailable) {
      throw const QuotaExhaustedException();
    }

    // 5. Cek apakah ada antrean yang sedang berjalan
    if (_activeTicket != null && _activeTicket!.isWaiting) {
      throw ActiveQueueExistsException(_activeTicket!.queueCode);
    }

    // 6. Hitung Skor Prioritas (Blueprint Bab 5.2):
    // Sp = w1 * C_nelayan + w2 * (Qsisa / Qtotal)
    final double cNelayan = _mockUser.categoryWeight; // 1.0 (nelayan kecil <= 5 GT)
    final double quotaRatio = _mockLetter.remainingRatio; // 270 / 450 = 0.6
    final double priorityScore = (AppConstants.priorityWeightCategory * cNelayan) +
        (AppConstants.priorityWeightQuota * quotaRatio); // 0.6 * 1.0 + 0.4 * 0.6 = 0.84

    // 7. Terbitkan tiket baru
    final newTicket = QueueTicket(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      spbnId: _mockStation.id,
      shipId: _mockShip.id,
      letterId: _mockLetter.id,
      queueCode: 'P1-004',
      priorityScore: double.parse(priorityScore.toStringAsFixed(2)),
      status: 'WAITING',
      estimatedWaitMinutes: 15,
      latCheckin: userLat,
      lngCheckin: userLon,
      createdAt: DateTime.now(),
    );

    _activeTicket = newTicket;
    _mockStation = _mockStation.copyWith(
      activeQueueCount: _mockStation.activeQueueCount + 1,
    );

    return newTicket;
  }

  @override
  Future<void> cancelQueue(int queueId) async {
    await Future.delayed(const Duration(milliseconds: 150));
    if (_activeTicket != null && _activeTicket!.id == queueId) {
      _activeTicket = _activeTicket!.copyWith(status: 'CANCELLED');
      _mockStation = _mockStation.copyWith(
        activeQueueCount: (_mockStation.activeQueueCount - 1).clamp(0, 999),
      );
    }
  }

  // Metode untuk pengujian dan reset state simulasi jika diperlukan
  void resetState() {
    _activeTicket = null;
  }

  void updateMockQuota({required double allocated, required double remaining}) {
    _mockLetter = _mockLetter.copyWith(
      allocatedQuota: allocated,
      remainingQuota: remaining,
    );
  }

  void updateMockUser(FishermanUser user) {
    _mockUser = user;
  }
}

// -------------------------------------------------------------
// Riverpod Providers untuk DI dan State Access di Layar UI
// -------------------------------------------------------------

/// Provider instance singleton MockSpbnRepository untuk simulasi offline
final mockSpbnRepositoryProvider = Provider<MockSpbnRepository>((ref) {
  return MockSpbnRepository();
});

/// Notifier flag apakah menggunakan Remote Laravel API atau Mock Data Simulasi.
/// Default bernilai false (menggunakan RemoteSpbnRepository yang terhubung ke Laravel API).
class UseMockRepositoryNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setMock(bool value) => state = value;
  void toggle() => state = !state;
}

final useMockRepositoryProvider =
    NotifierProvider<UseMockRepositoryNotifier, bool>(
  UseMockRepositoryNotifier.new,
);

/// Provider SpbnRepository utama aplikasi yang digunakan oleh seluruh antarmuka UI.
/// Secara default mengarah ke RemoteSpbnRepository sesuai permintaan Tahap 6.
final spbnRepositoryProvider = Provider<SpbnRepository>((ref) {
  final useMock = ref.watch(useMockRepositoryProvider);
  if (useMock) {
    return ref.watch(mockSpbnRepositoryProvider);
  }
  return ref.watch(remoteSpbnRepositoryProvider);
});

/// FutureProvider data profil nelayan
final fishermanProfileProvider = FutureProvider<FishermanUser>((ref) async {
  final repo = ref.watch(spbnRepositoryProvider);
  return repo.getFishermanProfile();
});

/// FutureProvider data kapal aktif
final activeShipProvider = FutureProvider<Ship>((ref) async {
  final repo = ref.watch(spbnRepositoryProvider);
  return repo.getActiveShip();
});

/// FutureProvider data surat rekomendasi & kuota
final recommendationLetterProvider = FutureProvider<RecommendationLetter>((ref) async {
  final repo = ref.watch(spbnRepositoryProvider);
  return repo.getRecommendationLetter();
});

/// FutureProvider data stasiun SPBN Madura
final spbnStationProvider = FutureProvider<SpbnStation>((ref) async {
  final repo = ref.watch(spbnRepositoryProvider);
  return repo.getSpbnStation();
});

/// FutureProvider riwayat transaksi
final transactionHistoryProvider = FutureProvider<List<TransactionHistory>>((ref) async {
  final repo = ref.watch(spbnRepositoryProvider);
  return repo.getTransactionHistories();
});

/// AsyncNotifier untuk mengelola status tiket antrean secara reaktif (Riverpod modern)
class ActiveQueueNotifier extends AsyncNotifier<QueueTicket?> {
  @override
  FutureOr<QueueTicket?> build() async {
    final repo = ref.watch(spbnRepositoryProvider);
    return repo.getActiveQueue();
  }

  Future<void> refreshQueue() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(spbnRepositoryProvider);
      return repo.getActiveQueue();
    });
  }

  Future<QueueTicket> takeQueue({
    required double userLat,
    required double userLon,
    required bool isMocked,
    required double accuracy,
  }) async {
    final repo = ref.read(spbnRepositoryProvider);
    state = const AsyncValue.loading();
    try {
      final ticket = await repo.takePriorityQueue(
        userLat: userLat,
        userLon: userLon,
        isMocked: isMocked,
        accuracy: accuracy,
      );
      state = AsyncValue.data(ticket);
      return ticket;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> cancelQueue(int queueId) async {
    final repo = ref.read(spbnRepositoryProvider);
    await repo.cancelQueue(queueId);
    state = const AsyncValue.data(null);
  }
}

final activeQueueNotifierProvider =
    AsyncNotifierProvider<ActiveQueueNotifier, QueueTicket?>(
  ActiveQueueNotifier.new,
);
