/// Model tiket antrean prioritas sesuai skema queues pada Blueprint TA.
class QueueTicket {
  final int id;
  final int spbnId;
  final int shipId;
  final int letterId;
  final String queueCode; // Contoh: 'P1-004'
  final double priorityScore; // Dihitung dengan rumus Sp = 0.6*C_nelayan + 0.4*(Qsisa/Qtotal)
  final String status; // 'WAITING', 'CALLED', 'SERVING', 'COMPLETED', 'CANCELLED'
  final int estimatedWaitMinutes;
  final double? latCheckin;
  final double? lngCheckin;
  final DateTime createdAt;

  const QueueTicket({
    required this.id,
    required this.spbnId,
    required this.shipId,
    required this.letterId,
    required this.queueCode,
    required this.priorityScore,
    this.status = 'WAITING',
    this.estimatedWaitMinutes = 15,
    this.latCheckin,
    this.lngCheckin,
    required this.createdAt,
  });

  bool get isWaiting => status.toUpperCase() == 'WAITING';
  bool get isCalled => status.toUpperCase() == 'CALLED';
  bool get isServing => status.toUpperCase() == 'SERVING';
  bool get isCompleted => status.toUpperCase() == 'COMPLETED';
  bool get isCancelled => status.toUpperCase() == 'CANCELLED';

  factory QueueTicket.fromJson(Map<String, dynamic> json) {
    return QueueTicket(
      id: json['id'] as int? ?? 0,
      spbnId: json['spbn_id'] as int? ?? 0,
      shipId: json['ship_id'] as int? ?? 0,
      letterId: json['letter_id'] as int? ?? 0,
      queueCode: json['queue_code'] as String? ?? 'P1-001',
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'WAITING',
      estimatedWaitMinutes: json['estimated_wait_minutes'] as int? ?? 15,
      latCheckin: (json['lat_checkin'] as num?)?.toDouble(),
      lngCheckin: (json['lng_checkin'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'spbn_id': spbnId,
      'ship_id': shipId,
      'letter_id': letterId,
      'queue_code': queueCode,
      'priority_score': priorityScore,
      'status': status,
      'estimated_wait_minutes': estimatedWaitMinutes,
      'lat_checkin': latCheckin,
      'lng_checkin': lngCheckin,
      'created_at': createdAt.toIso8601String(),
    };
  }

  QueueTicket copyWith({
    int? id,
    int? spbnId,
    int? shipId,
    int? letterId,
    String? queueCode,
    double? priorityScore,
    String? status,
    int? estimatedWaitMinutes,
    double? latCheckin,
    double? lngCheckin,
    DateTime? createdAt,
  }) {
    return QueueTicket(
      id: id ?? this.id,
      spbnId: spbnId ?? this.spbnId,
      shipId: shipId ?? this.shipId,
      letterId: letterId ?? this.letterId,
      queueCode: queueCode ?? this.queueCode,
      priorityScore: priorityScore ?? this.priorityScore,
      status: status ?? this.status,
      estimatedWaitMinutes: estimatedWaitMinutes ?? this.estimatedWaitMinutes,
      latCheckin: latCheckin ?? this.latCheckin,
      lngCheckin: lngCheckin ?? this.lngCheckin,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
