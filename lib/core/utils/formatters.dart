import 'package:intl/intl.dart';

/// Formatter utilitas untuk data transaksi, kuota solar, dan tanggal.
class AppFormatters {
  AppFormatters._();

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
  static final NumberFormat _numberFormat = NumberFormat('#,##0.0', 'id_ID');
  static final NumberFormat _integerFormat = NumberFormat('#,##0', 'id_ID');

  /// Format bilangan bulat / ribuan (contoh: "4.250")
  static String formatNumber(num value) {
    return _integerFormat.format(value);
  }

  /// Format volume solar dalam liter (contoh: "45.0 Liter")
  static String formatLiters(double liters) {
    return '${_numberFormat.format(liters)} L';
  }

  /// Format sisa kuota (contoh: "350 / 500 L")
  static String formatQuota(double remaining, double total) {
    return '${_integerFormat.format(remaining)} / ${_integerFormat.format(total)} L';
  }

  /// Format persentase kuota (contoh: "70.5%")
  static String formatPercentage(double ratio) {
    return '${(ratio * 100).toStringAsFixed(1)}%';
  }

  /// Format jarak dalam meter atau kilometer
  static String formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.toStringAsFixed(1)} m';
  }

  /// Format tanggal standar Indonesia
  static String formatDate(DateTime dateTime) {
    try {
      return _dateFormat.format(dateTime);
    } catch (_) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  /// Format tanggal dan waktu
  static String formatDateTime(DateTime dateTime) {
    try {
      return _dateTimeFormat.format(dateTime);
    } catch (_) {
      final hh = dateTime.hour.toString().padLeft(2, '0');
      final mm = dateTime.minute.toString().padLeft(2, '0');
      final dd = dateTime.day.toString().padLeft(2, '0');
      final mo = dateTime.month.toString().padLeft(2, '0');
      return '$dd/$mo/${dateTime.year} $hh:$mm WIB';
    }
  }

  /// Format waktu saja dengan padding 2 digit (contoh: "00:15")
  static String formatTime(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  /// Format waktu lengkap dengan zona WIB dan padding 2 digit (contoh: "00:15 WIB")
  static String formatTimeWib(DateTime dateTime) {
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');
    return '$hh:$mm WIB';
  }

  /// Format estimasi menit tunggu (contoh: "± 10 Menit")
  static String formatEstimatedWait(int minutes) {
    return '± $minutes Menit';
  }
}
