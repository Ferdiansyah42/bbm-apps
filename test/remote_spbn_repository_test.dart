import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:antrian_solar/core/constants/app_constants.dart';
import 'package:antrian_solar/core/network/dio_client.dart';
import 'package:antrian_solar/core/repositories/remote_spbn_repository.dart';

// Fake secure storage in memory for unit testing
class FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _storage[key] = value;
    } else {
      _storage.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _storage[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _storage.remove(key);
  }
}

void main() {
  group('DioClient & Sanctum Token Interceptor Tests', () {
    late FakeSecureStorage fakeStorage;
    late Dio testDio;
    late DioClient dioClient;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      testDio = Dio(BaseOptions(baseUrl: AppConstants.defaultBaseUrl));
      dioClient = DioClient(dio: testDio, secureStorage: fakeStorage);
    });

    test('Saves and reads Sanctum token correctly', () async {
      await dioClient.saveAuthToken('sanctum_test_token_123');
      final token = await dioClient.getAuthToken();
      expect(token, equals('sanctum_test_token_123'));

      await dioClient.clearAuthToken();
      final cleared = await dioClient.getAuthToken();
      expect(cleared, isNull);
    });
  });

  group('RemoteSpbnRepository Endpoint Contract Tests (Blueprint Tabel 3)', () {
    late FakeSecureStorage fakeStorage;
    late Dio testDio;
    late DioClient dioClient;
    late RemoteSpbnRepository remoteRepo;

    setUp(() {
      fakeStorage = FakeSecureStorage();
      testDio = Dio(BaseOptions(baseUrl: AppConstants.defaultBaseUrl));

      // Mock interceptor yang merespons sesuai spesifikasi kontrak REST API Blueprint Tabel 3
      testDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // 1. POST /api/v1/auth/login
            if (options.path.endsWith('/auth/login') && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'token': 'sanctum_bearer_token_xyz',
                    'user': {
                      'id': 1,
                      'name': 'Achmad Zaini',
                      'nik': '3528011204850002',
                      'phone': '081234567890',
                      'role': 'fisherman',
                      'fisherman_tier': 'small',
                      'fcm_token': 'fcm_token_test',
                    },
                  },
                ),
              );
            }

            // 2. GET /api/v1/spbn/status
            if (options.path.endsWith('/spbn/status') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': {
                      'id': 1,
                      'name': 'SPBN 58.693.01 Branta Pamekasan',
                      'latitude': -7.239400,
                      'longitude': 113.535600,
                      'radius_meters': 100.0,
                      'stock_liters': 12500.0,
                      'is_open': true,
                      'active_queue_count': 3,
                    },
                  },
                ),
              );
            }

            // 3. GET /api/v1/fisherman/dashboard
            if (options.path.endsWith('/fisherman/dashboard') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': {
                      'user': {
                        'id': 1,
                        'name': 'Achmad Zaini',
                        'nik': '3528011204850002',
                        'phone': '081234567890',
                        'role': 'fisherman',
                        'fisherman_tier': 'small',
                      },
                      'ship': {
                        'id': 1,
                        'user_id': 1,
                        'ship_name': 'KM Mina Jaya',
                        'gt_size': 3.0,
                        'engine_pk': 15.0,
                        'daily_need_est': 35.0,
                        'is_active': true,
                      },
                      'recommendation_letter': {
                        'id': 1,
                        'ship_id': 1,
                        'barcode_number': 'REK-DKP-2026-MADURA-001',
                        'allocated_quota': 450.0,
                        'remaining_quota': 270.0,
                        'valid_from': '2026-10-01T00:00:00Z',
                        'valid_until': '2027-01-01T00:00:00Z',
                        'status': 'ACTIVE',
                      },
                      'active_queue': {
                        'id': 102,
                        'spbn_id': 1,
                        'ship_id': 1,
                        'letter_id': 1,
                        'queue_code': 'P1-004',
                        'priority_score': 0.84,
                        'status': 'WAITING',
                        'estimated_wait_minutes': 15,
                        'created_at': '2026-11-16T10:00:00Z',
                      },
                    },
                  },
                ),
              );
            }

            // 4. POST /api/v1/queues/take
            if (options.path.endsWith('/queues/take') && options.method == 'POST') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'status': 'success',
                    'message': 'Antrean berhasil diterbitkan',
                    'data': {
                      'id': 105,
                      'spbn_id': 1,
                      'ship_id': 1,
                      'letter_id': 1,
                      'queue_code': 'P1-005',
                      'priority_score': 0.84,
                      'status': 'WAITING',
                      'estimated_wait_minutes': 20,
                      'lat_checkin': -7.2394,
                      'lng_checkin': 113.5356,
                      'created_at': '2026-11-16T10:30:00Z',
                    },
                  },
                ),
              );
            }

            // 5. GET /api/v1/transactions/history
            if (options.path.endsWith('/transactions/history') && options.method == 'GET') {
              return handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: 200,
                  data: {
                    'data': [
                      {
                        'id': 101,
                        'queue_id': 88,
                        'spbn_id': 1,
                        'ship_id': 1,
                        'letter_id': 1,
                        'officer_id': 3,
                        'transaction_ref': 'TRX-20261114-0041',
                        'volume_liters': 35.0,
                        'anomaly_score': 0.12,
                        'is_anomaly': false,
                        'anomaly_reasons': [],
                        'created_at': '2026-11-14T08:00:00Z',
                      },
                      {
                        'id': 98,
                        'queue_id': 65,
                        'spbn_id': 1,
                        'ship_id': 1,
                        'letter_id': 1,
                        'officer_id': 1,
                        'transaction_ref': 'TRX-20261106-0092',
                        'volume_liters': 70.0,
                        'anomaly_score': 0.86,
                        'is_anomaly': true,
                        'anomaly_reasons': [
                          'Frekuensi pembelian tinggi: 3 transaksi dalam 24 jam terakhir.',
                          'Jeda antar-pembelian terlalu singkat (1.5 jam).',
                        ],
                        'created_at': '2026-11-06T14:30:00Z',
                      },
                    ],
                  },
                ),
              );
            }

            return handler.next(options);
          },
        ),
      );

      dioClient = DioClient(dio: testDio, secureStorage: fakeStorage);
      remoteRepo = RemoteSpbnRepository(dioClient: dioClient);
    });

    test('POST /api/v1/auth/login authenticates and stores Sanctum token', () async {
      final user = await remoteRepo.login('3528011204850002', fcmToken: 'test_token');

      expect(user.name, equals('Achmad Zaini'));
      expect(user.nik, equals('3528011204850002'));
      expect(user.isSmallFisherman, isTrue);

      final savedToken = await fakeStorage.read(key: AppConstants.keyAuthToken);
      expect(savedToken, equals('sanctum_bearer_token_xyz'));
    });

    test('GET /api/v1/spbn/status retrieves station coordinates and stock', () async {
      final station = await remoteRepo.getSpbnStation();

      expect(station.name, equals('SPBN 58.693.01 Branta Pamekasan'));
      expect(station.latitude, equals(-7.239400));
      expect(station.longitude, equals(113.535600));
      expect(station.radiusMeters, equals(100.0));
      expect(station.stockLiters, equals(12500.0));
      expect(station.isOpen, isTrue);
    });

    test('GET /api/v1/fisherman/dashboard parses user, ship, letter, and queue', () async {
      final user = await remoteRepo.getFishermanProfile();
      expect(user.name, equals('Achmad Zaini'));

      final ship = await remoteRepo.getActiveShip();
      expect(ship.shipName, equals('KM Mina Jaya'));
      expect(ship.enginePk, equals(15.0));

      final letter = await remoteRepo.getRecommendationLetter();
      expect(letter.barcodeNumber, equals('REK-DKP-2026-MADURA-001'));
      expect(letter.remainingQuota, equals(270.0));
      expect(letter.allocatedQuota, equals(450.0));

      final queue = await remoteRepo.getActiveQueue();
      expect(queue?.queueCode, equals('P1-004'));
      expect(queue?.priorityScore, equals(0.84));
    });

    test('POST /api/v1/queues/take issues new queue ticket', () async {
      final ticket = await remoteRepo.takePriorityQueue(
        userLat: -7.2394,
        userLon: 113.5356,
        isMocked: false,
        accuracy: 8.0,
      );

      expect(ticket.queueCode, equals('P1-005'));
      expect(ticket.priorityScore, equals(0.84));
      expect(ticket.estimatedWaitMinutes, equals(20));
      expect(ticket.status, equals('WAITING'));
    });

    test('GET /api/v1/transactions/history parses normal and anomaly transactions', () async {
      final histories = await remoteRepo.getTransactionHistories();

      expect(histories.length, equals(2));
      expect(histories[0].isAnomaly, isFalse);
      expect(histories[0].volumeLiters, equals(35.0));

      expect(histories[1].isAnomaly, isTrue);
      expect(histories[1].anomalyScore, equals(0.86));
      expect(histories[1].anomalyReasons.length, equals(2));
    });
  });
}
