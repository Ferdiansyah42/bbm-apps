/// Model data surat rekomendasi DKP sesuai skema recommendation_letters pada Blueprint TA.
class RecommendationLetter {
  final int id;
  final int shipId;
  final String barcodeNumber;
  final double allocatedQuota; // Total kuota bulanan (liter, contoh: 450 L)
  final double remainingQuota; // Sisa kuota berjalan (liter, contoh: 270 L)
  final DateTime validFrom;
  final DateTime validUntil; // Masa berlaku 3 bulan
  final String status; // 'ACTIVE', 'EXPIRED', 'EXHAUSTED'

  const RecommendationLetter({
    required this.id,
    required this.shipId,
    required this.barcodeNumber,
    required this.allocatedQuota,
    required this.remainingQuota,
    required this.validFrom,
    required this.validUntil,
    this.status = 'ACTIVE',
  });

  /// Kuota yang sudah terpakai
  double get quotaUsed => (allocatedQuota - remainingQuota).clamp(0.0, allocatedQuota);

  /// Rasio sisa kuota (Qsisa / Qtotal) untuk Priority Scheduling (Blueprint Bab 5.2)
  double get remainingRatio => allocatedQuota > 0 ? (remainingQuota / allocatedQuota).clamp(0.0, 1.0) : 0.0;

  /// Persentase kuota terpakai (0 - 100%)
  double get usedPercentage => allocatedQuota > 0 ? (quotaUsed / allocatedQuota) * 100.0 : 0.0;

  /// Sisa hari sebelum surat rekomendasi kedaluwarsa
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(validUntil)) return 0;
    return validUntil.difference(now).inDays;
  }

  /// Cek apakah surat kedaluwarsa
  bool get isExpired => DateTime.now().isAfter(validUntil) || status.toUpperCase() == 'EXPIRED';

  /// Cek apakah kuota masih dapat digunakan
  bool get isQuotaAvailable => remainingQuota > 0 && !isExpired;

  factory RecommendationLetter.fromJson(Map<String, dynamic> json) {
    return RecommendationLetter(
      id: json['id'] as int? ?? 0,
      shipId: json['ship_id'] as int? ?? 0,
      barcodeNumber: json['barcode_number'] as String? ?? '',
      allocatedQuota: (json['allocated_quota'] as num?)?.toDouble() ?? 0.0,
      remainingQuota: (json['remaining_quota'] as num?)?.toDouble() ?? 0.0,
      validFrom: json['valid_from'] != null
          ? DateTime.tryParse(json['valid_from'].toString()) ?? DateTime.now()
          : DateTime.now(),
      validUntil: json['valid_until'] != null
          ? DateTime.tryParse(json['valid_until'].toString()) ?? DateTime.now().add(const Duration(days: 90))
          : DateTime.now().add(const Duration(days: 90)),
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ship_id': shipId,
      'barcode_number': barcodeNumber,
      'allocated_quota': allocatedQuota,
      'remaining_quota': remainingQuota,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'status': status,
    };
  }

  RecommendationLetter copyWith({
    int? id,
    int? shipId,
    String? barcodeNumber,
    double? allocatedQuota,
    double? remainingQuota,
    DateTime? validFrom,
    DateTime? validUntil,
    String? status,
  }) {
    return RecommendationLetter(
      id: id ?? this.id,
      shipId: shipId ?? this.shipId,
      barcodeNumber: barcodeNumber ?? this.barcodeNumber,
      allocatedQuota: allocatedQuota ?? this.allocatedQuota,
      remainingQuota: remainingQuota ?? this.remainingQuota,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      status: status ?? this.status,
    );
  }
}
