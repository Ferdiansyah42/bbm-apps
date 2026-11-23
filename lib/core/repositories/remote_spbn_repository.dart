import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../network/dio_client.dart';
import 'spbn_repository.dart';

/// Implementasi SpbnRepository yang terhubung ke Backend Laravel REST API sungguhan.
/// Sesuai kontrak API pada Blueprint TA Bab 6 & Tabel 3.
class RemoteSpbnRepository implements SpbnRepository {
  final DioClient dioClient;

  // Cache dashboard response untuk efisiensi koneksi pesisir
  Map<String, dynamic>? _cachedDashboardData;
  DateTime? _lastDashboardFetchTime;

  RemoteSpbnRepository({required this.dioClient});

  /// 1. POST /api/v1/auth/login
  /// Autentikasi NIK / No. HP dan registrasi fcm_token perangkat (Public)
  @override
  Future<FishermanUser> login(String identifier, {String? fcmToken}) async {
    final response = await dioClient.post(
      '/auth/login',
      data: {
        'nik': identifier,
        'identifier': identifier,
        'fcm_token': ?fcmToken,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      // Simpan Sanctum token ke FlutterSecureStorage
      final token = data['token'] as String? ??
          data['access_token'] as String? ??
          data['data']?['token'] as String?;

      if (token != null && token.isNotEmpty) {
        await dioClient.saveAuthToken(token);
      }

      final userData = data['user'] ?? data['data']?['user'] ?? data['data'];
      if (userData is Map<String, dynamic>) {
        return FishermanUser.fromJson(userData);
      }
    }

    throw const ApiException(message: 'Format respon autentikasi server tidak valid.');
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.post('/auth/logout');
    } catch (_) {}
    await dioClient.clearAuthToken();
    _cachedDashboardData = null;
  }

  /// 2. GET /api/v1/spbn/status
  /// Mengambil koordinat SPBN, radius geofence, stok solar, dan jumlah antrean (Sanctum)
  @override
  Future<SpbnStation> getSpbnStation() async {
    final response = await dioClient.get('/spbn/status');
    final data = response.data;

    final stationJson = _extractDataMap(data);
    return SpbnStation.fromJson(stationJson);
  }

  /// 3. GET /api/v1/fisherman/dashboard
  /// Mengambil profil kapal, sisa kuota rekomendasi, barcode, dan antrean aktif (Sanctum)
  Future<Map<String, dynamic>> _fetchDashboardData({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedDashboardData != null &&
        _lastDashboardFetchTime != null &&
        now.difference(_lastDashboardFetchTime!).inSeconds < 10) {
      return _cachedDashboardData!;
    }

    final response = await dioClient.get('/fisherman/dashboard');
    final data = _extractDataMap(response.data);

    _cachedDashboardData = data;
    _lastDashboardFetchTime = now;
    return data;
  }

  @override
  Future<FishermanUser> getFishermanProfile() async {
    final dashboard = await _fetchDashboardData();
    final userJson = dashboard['user'] ?? dashboard['fisherman'];
    if (userJson is Map<String, dynamic>) {
      return FishermanUser.fromJson(userJson);
    }
    return FishermanUser.fromJson(dashboard);
  }

  @override
  Future<Ship> getActiveShip() async {
    final dashboard = await _fetchDashboardData();
    final shipJson = dashboard['ship'] ?? dashboard['active_ship'];
    if (shipJson is Map<String, dynamic>) {
      return Ship.fromJson(shipJson);
    }
    throw const ApiException(message: 'Data kapal nelayan tidak ditemukan pada server.');
  }

  @override
  Future<RecommendationLetter> getRecommendationLetter() async {
    final dashboard = await _fetchDashboardData();
    final letterJson = dashboard['recommendation_letter'] ?? dashboard['letter'];
    if (letterJson is Map<String, dynamic>) {
      return RecommendationLetter.fromJson(letterJson);
    }
    throw const ApiException(message: 'Surat rekomendasi tidak ditemukan pada server.');
  }

  @override
  Future<QueueTicket?> getActiveQueue() async {
    final dashboard = await _fetchDashboardData(forceRefresh: true);
    final queueJson = dashboard['active_queue'] ?? dashboard['queue'];
    if (queueJson is Map<String, dynamic>) {
      return QueueTicket.fromJson(queueJson);
    }
    return null;
  }

  /// 4. POST /api/v1/queues/take
  /// Validasi lokasi geofence, cek anti-mock GPS, dan penerbitan nomor antrean (Sanctum)
  @override
  Future<QueueTicket> takePriorityQueue({
    required double userLat,
    required double userLon,
    required bool isMocked,
    required double accuracy,
  }) async {
    final response = await dioClient.post(
      '/queues/take',
      data: {
        'lat_checkin': userLat,
        'lng_checkin': userLon,
        'is_mocked': isMocked,
        'accuracy': accuracy,
      },
    );

    final ticketJson = _extractDataMap(response.data);
    _cachedDashboardData = null; // Reset cache agar getActiveQueue selalu terbaru
    return QueueTicket.fromJson(ticketJson);
  }

  /// 5. GET /api/v1/transactions/history
  /// Mengambil riwayat transaksi pengisian solar nelayan (Sanctum)
  @override
  Future<List<TransactionHistory>> getTransactionHistories() async {
    final response = await dioClient.get('/transactions/history');
    final data = response.data;

    List<dynamic> items = [];
    if (data is List) {
      items = data;
    } else if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        items = data['data'] as List<dynamic>;
      } else if (data['transactions'] is List) {
        items = data['transactions'] as List<dynamic>;
      }
    }

    return items
        .map((item) => TransactionHistory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Pembatalan tiket antrean aktif
  @override
  Future<void> cancelQueue(int queueId) async {
    await dioClient.delete('/queues/$queueId');
    _cachedDashboardData = null;
  }

  Map<String, dynamic> _extractDataMap(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('data') && responseData['data'] is Map<String, dynamic>) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData;
    }
    return {};
  }
}

// -------------------------------------------------------------
// Riverpod Provider untuk RemoteSpbnRepository
// -------------------------------------------------------------

/// Provider instance RemoteSpbnRepository yang terhubung ke DioClient
final remoteSpbnRepositoryProvider = Provider<RemoteSpbnRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RemoteSpbnRepository(dioClient: dioClient);
});
