/// Model data kapal nelayan sesuai skema tabel ships pada Blueprint TA.
class Ship {
  final int id;
  final int userId;
  final String shipName;
  final double gtSize; // Gross Tonnage (contoh: 3.0 GT)
  final double enginePk; // Daya mesin dalam PK/HP (contoh: 15.0 PK)
  final double dailyNeedEst; // Estimasi kebutuhan harian (liter)
  final bool isActive;

  const Ship({
    required this.id,
    required this.userId,
    required this.shipName,
    required this.gtSize,
    required this.enginePk,
    required this.dailyNeedEst,
    this.isActive = true,
  });

  factory Ship.fromJson(Map<String, dynamic> json) {
    return Ship(
      id: json['id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      shipName: json['ship_name'] as String? ?? '',
      gtSize: (json['gt_size'] as num?)?.toDouble() ?? 0.0,
      enginePk: (json['engine_pk'] as num?)?.toDouble() ?? 0.0,
      dailyNeedEst: (json['daily_need_est'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ship_name': shipName,
      'gt_size': gtSize,
      'engine_pk': enginePk,
      'daily_need_est': dailyNeedEst,
      'is_active': isActive,
    };
  }

  Ship copyWith({
    int? id,
    int? userId,
    String? shipName,
    double? gtSize,
    double? enginePk,
    double? dailyNeedEst,
    bool? isActive,
  }) {
    return Ship(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      shipName: shipName ?? this.shipName,
      gtSize: gtSize ?? this.gtSize,
      enginePk: enginePk ?? this.enginePk,
      dailyNeedEst: dailyNeedEst ?? this.dailyNeedEst,
      isActive: isActive ?? this.isActive,
    );
  }
}
