import '../models/models.dart';

/// Kontrak repository SPBN untuk aplikasi mobile nelayan
abstract class SpbnRepository {
  Future<FishermanUser> getFishermanProfile();
  Future<Ship> getActiveShip();
  Future<RecommendationLetter> getRecommendationLetter();
  Future<SpbnStation> getSpbnStation();
  Future<QueueTicket?> getActiveQueue();
  Future<List<TransactionHistory>> getTransactionHistories();

  /// Mengambil antrean prioritas dengan validasi geofence dan keamanan GPS (Blueprint Bab 3.3 & 5.2)
  Future<QueueTicket> takePriorityQueue({
    required double userLat,
    required double userLon,
    required bool isMocked,
    required double accuracy,
  });

  /// Membatalkan antrean aktif
  Future<void> cancelQueue(int queueId);
}
