import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../repositories/mock_spbn_repository.dart';
import '../utils/haversine_calculator.dart';

/// Status evaluasi spasial dan keamanan GPS nelayan
enum GeofenceValidationStatus {
  initial,
  checking,
  validInside, // Berada di dalam radius SPBN, GPS asli, akurasi memadai
  outsideGeofence, // Berada di luar batas radius fisik SPBN (d > Rspbn)
  mockGpsDetected, // TERDETEKSI LOKASI PALSU (FAKE GPS)
  accuracyTooLow, // Galat akurasi GPS melebihi 35.0 meter
  permissionDenied, // Izin akses lokasi ditolak oleh pengguna
  serviceDisabled, // Layanan GPS perangkat nonaktif
  error,
}

/// State representasi hasil validasi geofencing dan anti-mock GPS
class GeofenceSecurityState {
  final GeofenceValidationStatus status;
  final Position? position;
  final double? distanceMeters;
  final bool isInsideGeofence;
  final bool isMocked;
  final double? accuracy;
  final String message;
  final DateTime timestamp;

  const GeofenceSecurityState({
    required this.status,
    this.position,
    this.distanceMeters,
    this.isInsideGeofence = false,
    this.isMocked = false,
    this.accuracy,
    required this.message,
    required this.timestamp,
  });

  /// Status apakah nelayan memenuhi semua syarat untuk mengambil tiket antrean:
  /// (1) Berada di radius SPBN, (2) isMocked == false, (3) accuracy <= 35m
  bool get canTakeQueue =>
      status == GeofenceValidationStatus.validInside &&
      isInsideGeofence &&
      !isMocked &&
      (accuracy ?? 999.0) <= AppConstants.maxAllowedGpsAccuracyMeters;

  factory GeofenceSecurityState.initial() => GeofenceSecurityState(
        status: GeofenceValidationStatus.initial,
        message: 'Menginisialisasi sensor lokasi...',
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.checking() => GeofenceSecurityState(
        status: GeofenceValidationStatus.checking,
        message: 'Memindai posisi GPS dan memvalidasi geofence SPBN...',
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.serviceDisabled() => GeofenceSecurityState(
        status: GeofenceValidationStatus.serviceDisabled,
        message: 'Layanan lokasi (GPS) pada smartphone belum aktif. Mohon aktifkan GPS.',
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.permissionDenied() => GeofenceSecurityState(
        status: GeofenceValidationStatus.permissionDenied,
        message: 'Izin lokasi ditolak. Aplikasi memerlukan izin lokasi presisi untuk antrean SPBN.',
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.mockDetected(Position position) => GeofenceSecurityState(
        status: GeofenceValidationStatus.mockGpsDetected,
        position: position,
        isMocked: true,
        accuracy: position.accuracy,
        message: LocationSecurityService.mockGpsWarning,
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.accuracyTooLow(Position position) => GeofenceSecurityState(
        status: GeofenceValidationStatus.accuracyTooLow,
        position: position,
        isMocked: position.isMocked,
        accuracy: position.accuracy,
        message:
            'Akurasi sinyal GPS lemah (${position.accuracy.toStringAsFixed(1)} m > ${AppConstants.maxAllowedGpsAccuracyMeters} m). Harap bergerak ke dermaga terbuka.',
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.outsideGeofence({
    required Position position,
    required double distanceMeters,
    required double radiusMeters,
  }) =>
      GeofenceSecurityState(
        status: GeofenceValidationStatus.outsideGeofence,
        position: position,
        distanceMeters: distanceMeters,
        isInsideGeofence: false,
        isMocked: false,
        accuracy: position.accuracy,
        message:
            'Anda berada di luar radius SPBN (${distanceMeters.toStringAsFixed(1)} m dari pusat dermaga, batas: ${radiusMeters.toStringAsFixed(0)} m).',
        timestamp: DateTime.now(),
      );

  factory GeofenceSecurityState.validInside({
    required Position position,
    required double distanceMeters,
    required double radiusMeters,
  }) =>
      GeofenceSecurityState(
        status: GeofenceValidationStatus.validInside,
        position: position,
        distanceMeters: distanceMeters,
        isInsideGeofence: true,
        isMocked: false,
        accuracy: position.accuracy,
        message:
            'Lokasi terverifikasi di area SPBN (${distanceMeters.toStringAsFixed(1)} m dari pusat, akurasi: ${position.accuracy.toStringAsFixed(1)} m).',
        timestamp: DateTime.now(),
      );
}

/// Service untuk mengevaluasi posisi GPS, Haversine geofence, dan keamanan anti-Fake GPS.
/// Sesuai spesifikasi Lapis 1 Blueprint TA.
class LocationSecurityService {
  static const String mockGpsWarning = 'TERDETEKSI LOKASI PALSU (FAKE GPS)';

  const LocationSecurityService();

  /// Memeriksa status service GPS aktif dan meminta izin jika diperlukan
  Future<bool> checkPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Mengevaluasi objek Position secara deterministik
  GeofenceSecurityState evaluatePosition(
    Position position, {
    double spbnLat = AppConstants.defaultSpbnLatitude,
    double spbnLon = AppConstants.defaultSpbnLongitude,
    double radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
  }) {
    // 1. Deteksi Fake GPS / Mock Location
    if (position.isMocked) {
      return GeofenceSecurityState.mockDetected(position);
    }

    // 2. Validasi Akurasi Sinyal GPS (accuracy <= 35.0 meter)
    if (position.accuracy > AppConstants.maxAllowedGpsAccuracyMeters) {
      return GeofenceSecurityState.accuracyTooLow(position);
    }

    // 3. Hitung jarak menggunakan Haversine Formula (R_bumi = 6.371.000 m)
    final double distance = HaversineCalculator.calculateDistance(
      lat1: position.latitude,
      lon1: position.longitude,
      lat2: spbnLat,
      lon2: spbnLon,
    );

    // 4. Validasi Radius Geofence (distance <= radiusMeters)
    if (distance <= radiusMeters) {
      return GeofenceSecurityState.validInside(
        position: position,
        distanceMeters: distance,
        radiusMeters: radiusMeters,
      );
    } else {
      return GeofenceSecurityState.outsideGeofence(
        position: position,
        distanceMeters: distance,
        radiusMeters: radiusMeters,
      );
    }
  }

  /// Mengambil posisi saat ini secara langsung dari sensor GPS dan mengevaluasinya
  Future<GeofenceSecurityState> getCurrentLocationSecurity({
    double spbnLat = AppConstants.defaultSpbnLatitude,
    double spbnLon = AppConstants.defaultSpbnLongitude,
    double radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
  }) async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return GeofenceSecurityState.serviceDisabled();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return GeofenceSecurityState.permissionDenied();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return GeofenceSecurityState.permissionDenied();
    }

    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return evaluatePosition(
        position,
        spbnLat: spbnLat,
        spbnLon: spbnLon,
        radiusMeters: radiusMeters,
      );
    } catch (e) {
      return GeofenceSecurityState(
        status: GeofenceValidationStatus.error,
        message: 'Gagal memperoleh koordinat GPS: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Stream posisi GPS live dari perangkat
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 2, // Update setiap perubahan 2 meter
      ),
    );
  }
}

// -------------------------------------------------------------
// Riverpod Providers untuk Geofence & Location Security
// -------------------------------------------------------------

/// Provider instance singleton LocationSecurityService
final locationSecurityServiceProvider = Provider<LocationSecurityService>((ref) {
  return const LocationSecurityService();
});

/// StreamProvider untuk posisi GPS mentah perangkat secara real-time
final rawPositionStreamProvider = StreamProvider.autoDispose<Position>((ref) async* {
  final service = ref.watch(locationSecurityServiceProvider);
  final hasPermission = await service.checkPermission();
  if (!hasPermission) {
    throw Exception('Izin lokasi ditolak atau GPS tidak aktif.');
  }

  yield* service.getPositionStream();
});

/// StreamProvider untuk status keamanan Geofencing secara real-time
final liveGeofenceSecurityProvider =
    StreamProvider.autoDispose<GeofenceSecurityState>((ref) async* {
  final service = ref.watch(locationSecurityServiceProvider);
  final stationAsync = ref.watch(spbnStationProvider);

  final spbnStation = stationAsync.value;
  final double spbnLat = spbnStation?.latitude ?? AppConstants.defaultSpbnLatitude;
  final double spbnLon = spbnStation?.longitude ?? AppConstants.defaultSpbnLongitude;
  final double radiusMeters = spbnStation?.radiusMeters ?? AppConstants.defaultGeofenceRadiusMeters;

  final hasPermission = await service.checkPermission();
  if (!hasPermission) {
    yield GeofenceSecurityState.permissionDenied();
    return;
  }

  // Emisi evaluasi pertama
  final initialStatus = await service.getCurrentLocationSecurity(
    spbnLat: spbnLat,
    spbnLon: spbnLon,
    radiusMeters: radiusMeters,
  );
  yield initialStatus;

  // Lanjutkan dengan stream pergerakan nelayan
  await for (final position in service.getPositionStream()) {
    yield service.evaluatePosition(
      position,
      spbnLat: spbnLat,
      spbnLon: spbnLon,
      radiusMeters: radiusMeters,
    );
  }
});

/// AsyncNotifier untuk aksi interaktif (misal tombol refresh lokasi atau simulasi demo)
class GeofenceSecurityNotifier extends AsyncNotifier<GeofenceSecurityState> {
  @override
  FutureOr<GeofenceSecurityState> build() async {
    final service = ref.watch(locationSecurityServiceProvider);
    final stationAsync = ref.watch(spbnStationProvider);
    final station = stationAsync.value;

    return service.getCurrentLocationSecurity(
      spbnLat: station?.latitude ?? AppConstants.defaultSpbnLatitude,
      spbnLon: station?.longitude ?? AppConstants.defaultSpbnLongitude,
      radiusMeters: station?.radiusMeters ?? AppConstants.defaultGeofenceRadiusMeters,
    );
  }

  /// Memindai ulang lokasi GPS perangkat saat ini
  Future<void> refreshLocation() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(locationSecurityServiceProvider);
      final station = ref.read(spbnStationProvider).value;
      return service.getCurrentLocationSecurity(
        spbnLat: station?.latitude ?? AppConstants.defaultSpbnLatitude,
        spbnLon: station?.longitude ?? AppConstants.defaultSpbnLongitude,
        radiusMeters: station?.radiusMeters ?? AppConstants.defaultGeofenceRadiusMeters,
      );
    });
  }

  /// Metode simulasi untuk mendemokan skenario kepada dosen tanpa harus berada di dermaga Madura
  void simulateLocation({
    required double latitude,
    required double longitude,
    required bool isMocked,
    required double accuracy,
  }) {
    final service = ref.read(locationSecurityServiceProvider);
    final station = ref.read(spbnStationProvider).value;

    final mockPosition = Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: accuracy,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      isMocked: isMocked,
    );

    final evaluation = service.evaluatePosition(
      mockPosition,
      spbnLat: station?.latitude ?? AppConstants.defaultSpbnLatitude,
      spbnLon: station?.longitude ?? AppConstants.defaultSpbnLongitude,
      radiusMeters: station?.radiusMeters ?? AppConstants.defaultGeofenceRadiusMeters,
    );

    state = AsyncValue.data(evaluation);
  }
}

final geofenceSecurityNotifierProvider =
    AsyncNotifierProvider<GeofenceSecurityNotifier, GeofenceSecurityState>(
  GeofenceSecurityNotifier.new,
);
