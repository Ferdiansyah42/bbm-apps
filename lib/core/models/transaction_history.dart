/// Model riwayat transaksi pengisian solar sesuai skema transactions pada Blueprint TA.
class TransactionHistory {
  final int id;
  final int? queueId;
  final int spbnId;
  final int shipId;
  final int letterId;
  final int? officerId;
  final String transactionRef;
  final double volumeLiters;
  final double? anomalyScore; // Nilai A_score [0, 1] dari FastAPI Isolation Forest
  final bool isAnomaly; // Hasil prediksi ML (-1 -> is_anomaly = true)
  final List<String> anomalyReasons; // Penjelasan tekstual alasan anomali
  final DateTime createdAt;

  const TransactionHistory({
    required this.id,
    this.queueId,
    required this.spbnId,
    required this.shipId,
    required this.letterId,
    this.officerId,
    required this.transactionRef,
    required this.volumeLiters,
    this.anomalyScore,
    this.isAnomaly = false,
    this.anomalyReasons = const [],
    required this.createdAt,
  });

  factory TransactionHistory.fromJson(Map<String, dynamic> json) {
    return TransactionHistory(
      id: json['id'] as int? ?? 0,
      queueId: json['queue_id'] as int?,
      spbnId: json['spbn_id'] as int? ?? 0,
      shipId: json['ship_id'] as int? ?? 0,
      letterId: json['letter_id'] as int? ?? 0,
      officerId: json['officer_id'] as int?,
      transactionRef: json['transaction_ref'] as String? ?? 'TRX-SAMPLE',
      volumeLiters: (json['volume_liters'] as num?)?.toDouble() ?? 0.0,
      anomalyScore: (json['anomaly_score'] as num?)?.toDouble(),
      isAnomaly: json['is_anomaly'] as bool? ?? false,
      anomalyReasons: (json['anomaly_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'queue_id': queueId,
      'spbn_id': spbnId,
      'ship_id': shipId,
      'letter_id': letterId,
      'officer_id': officerId,
      'transaction_ref': transactionRef,
      'volume_liters': volumeLiters,
      'anomaly_score': anomalyScore,
      'is_anomaly': isAnomaly,
      'anomaly_reasons': anomalyReasons,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TransactionHistory copyWith({
    int? id,
    int? queueId,
    int? spbnId,
    int? shipId,
    int? letterId,
    int? officerId,
    String? transactionRef,
    double? volumeLiters,
    double? anomalyScore,
    bool? isAnomaly,
    List<String>? anomalyReasons,
    DateTime? createdAt,
  }) {
    return TransactionHistory(
      id: id ?? this.id,
      queueId: queueId ?? this.queueId,
      spbnId: spbnId ?? this.spbnId,
      shipId: shipId ?? this.shipId,
      letterId: letterId ?? this.letterId,
      officerId: officerId ?? this.officerId,
      transactionRef: transactionRef ?? this.transactionRef,
      volumeLiters: volumeLiters ?? this.volumeLiters,
      anomalyScore: anomalyScore ?? this.anomalyScore,
      isAnomaly: isAnomaly ?? this.isAnomaly,
      anomalyReasons: anomalyReasons ?? this.anomalyReasons,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
