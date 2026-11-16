import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';

/// Status validasi keamanan pembacaan GPS untuk mencegah spoofing / fake GPS.
enum GpsSecurityStatus {
  valid,
  mockLocationDetected,
  accuracyTooLow,
  permissionDenied,
  serviceDisabled,
}

/// Hasil evaluasi keamanan sinyal GPS
class GpsSecurityResult {
  final bool isValid;
  final GpsSecurityStatus status;
  final String message;
  final Position? position;

  const GpsSecurityResult({
    required this.isValid,
    required this.status,
    required this.message,
    this.position,
  });

  factory GpsSecurityResult.valid(Position position) => GpsSecurityResult(
        isValid: true,
        status: GpsSecurityStatus.valid,
        message: 'Lokasi GPS valid dan akurat.',
        position: position,
      );

  factory GpsSecurityResult.mockDetected(Position position) => GpsSecurityResult(
        isValid: false,
        status: GpsSecurityStatus.mockLocationDetected,
        message: 'Terdeteksi aplikasi lokasi palsu (Fake GPS/Mock Location). Pengambilan antrean diblokir!',
        position: position,
      );

  factory GpsSecurityResult.lowAccuracy(Position position) => GpsSecurityResult(
        isValid: false,
        status: GpsSecurityStatus.accuracyTooLow,
        message:
            'Akurasi sinyal GPS terlalu rendah (${position.accuracy.toStringAsFixed(1)} m > ${AppConstants.maxAllowedGpsAccuracyMeters} m). Pastikan Anda berada di ruang terbuka.',
        position: position,
      );

  factory GpsSecurityResult.permissionDenied() => const GpsSecurityResult(
        isValid: false,
        status: GpsSecurityStatus.permissionDenied,
        message: 'Izin akses lokasi GPS ditolak oleh pengguna.',
      );

  factory GpsSecurityResult.serviceDisabled() => const GpsSecurityResult(
        isValid: false,
        status: GpsSecurityStatus.serviceDisabled,
        message: 'Layanan lokasi (GPS) pada perangkat dalam keadaan nonaktif.',
      );
}

/// Service untuk memvalidasi posisi GPS dan mendeteksi Mock Location sesuai Blueprint TA Bab 3.3.
class GpsSecurityService {
  GpsSecurityService._();

  /// Mengevaluasi objek Position dari Geolocator
  static GpsSecurityResult validatePosition(Position position) {
    // 1. Cek properti isMocked (Android Mock Location / Fake GPS)
    if (position.isMocked) {
      return GpsSecurityResult.mockDetected(position);
    }

    // 2. Cek batas toleransi galat akurasi GPS (accuracy > 35 meter)
    if (position.accuracy > AppConstants.maxAllowedGpsAccuracyMeters) {
      return GpsSecurityResult.lowAccuracy(position);
    }

    return GpsSecurityResult.valid(position);
  }

  /// Memeriksa status izin lokasi dan mengambil posisi saat ini dengan validasi keamanan
  static Future<GpsSecurityResult> getCurrentSecurePosition() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return GpsSecurityResult.serviceDisabled();
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return GpsSecurityResult.permissionDenied();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return GpsSecurityResult.permissionDenied();
    }

    final Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return validatePosition(position);
  }
}
