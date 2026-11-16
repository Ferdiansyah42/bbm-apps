/// Konstanta aplikasi antrian solar nelayan SPBN Madura sesuai Blueprint Teknis.
class AppConstants {
  AppConstants._();

  // Nama Aplikasi
  static const String appName = 'Antrian Solar Nelayan';
  static const String appTagline = 'Sistem Antrean & Pengawasan Kuota Solar Nelayan';

  // Koordinat Default SPBN Madura (SPBN Pelabuhan Perikanan Branta Pamekasan - Madura)
  static const String defaultSpbnName = 'SPBN 58.693.01 Branta Pamekasan';
  static const double defaultSpbnLatitude = -7.239400;
  static const double defaultSpbnLongitude = 113.535600;

  // Parameter Geofencing Spasial (Sesuai Blueprint Bab 3.3 & 5.1)
  /// Radius batas fisik geofence antrean SPBN (default 100 meter)
  static const double defaultGeofenceRadiusMeters = 100.0;

  /// Jari-jari bumi untuk formula Haversine (Rbumi = 6.371.000 meter)
  static const double earthRadiusMeters = 6371000.0;

  /// Batas toleransi galat akurasi GPS maksimum (accuracy > 35 meter ditolak demi mencegah spoofing)
  static const double maxAllowedGpsAccuracyMeters = 35.0;

  // Bobot Priority Scheduling (Sesuai Blueprint Bab 5.2)
  /// Bobot kategori kapal/nelayan kecil tradisional (w1 = 0.6)
  static const double priorityWeightCategory = 0.6;

  /// Bobot rasio sisa kuota (w2 = 0.4)
  static const double priorityWeightQuota = 0.4;

  // Konfigurasi Masa Berlaku Surat Rekomendasi
  static const int recommendationValidityDays = 90; // 3 bulan

  // Storage Keys (Secure Storage & Shared Preferences)
  static const String keyAuthToken = 'auth_token';
  static const String keyUserNik = 'user_nik';
  static const String keyUserData = 'user_data';
  static const String keyCachedQr = 'cached_qr_code';
  static const String keyFcmToken = 'fcm_token';

  // Network Defaults
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api/v1'; // Android emulator localhost
  static const int connectTimeoutSeconds = 15;
  static const int receiveTimeoutSeconds = 15;
}
