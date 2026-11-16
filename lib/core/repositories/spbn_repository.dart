import '../models/models.dart';

/// Kontrak repository SPBN untuk aplikasi mobile nelayan
abstract class SpbnRepository {
  /// Autentikasi NIK / No. HP dan registrasi FCM token (POST /api/v1/auth/login)
  Future<FishermanUser> login(String identifier, {String? fcmToken});

  /// Keluar dari sesi login dan membersihkan token
  Future<void> logout();

  /// Mengambil profil lengkap nelayan (GET /api/v1/fisherman/dashboard)
  Future<FishermanUser> getFishermanProfile();

  /// Mengambil data kapal aktif (GET /api/v1/fisherman/dashboard)
  Future<Ship> getActiveShip();

  /// Mengambil data surat rekomendasi & kuota bulanan (GET /api/v1/fisherman/dashboard)
  Future<RecommendationLetter> getRecommendationLetter();

  /// Mengambil status koordinat, stok solar, dan antrean SPBN (GET /api/v1/spbn/status)
  Future<SpbnStation> getSpbnStation();

  /// Mengambil tiket antrean aktif nelayan (GET /api/v1/fisherman/dashboard)
  Future<QueueTicket?> getActiveQueue();

  /// Mengambil riwayat transaksi pengisian solar nelayan (GET /api/v1/transactions/history)
  Future<List<TransactionHistory>> getTransactionHistories();

  /// Mengambil antrean prioritas dengan validasi geofence dan keamanan GPS (POST /api/v1/queues/take)
  Future<QueueTicket> takePriorityQueue({
    required double userLat,
    required double userLon,
    required bool isMocked,
    required double accuracy,
  });

  /// Membatalkan antrean aktif (DELETE /api/v1/queues/{id} atau POST /api/v1/queues/{id}/cancel)
  Future<void> cancelQueue(int queueId);
}
