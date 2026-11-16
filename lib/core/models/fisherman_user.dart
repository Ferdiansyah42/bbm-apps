/// Model data pengguna nelayan sesuai skema tabel users pada Blueprint TA.
class FishermanUser {
  final int id;
  final String name;
  final String nik;
  final String phone;
  final String role;
  final String fishermanTier; // 'small' (<= 5 GT) atau 'medium' (> 5 GT)
  final String? fcmToken;

  const FishermanUser({
    required this.id,
    required this.name,
    required this.nik,
    required this.phone,
    this.role = 'fisherman',
    this.fishermanTier = 'small',
    this.fcmToken,
  });

  /// Bobot kategori untuk algoritma Priority Scheduling (Blueprint Bab 5.2)
  /// C_nelayan = 1.0 untuk nelayan kecil tradisional <= 5 GT, 0.5 untuk kategori di atasnya.
  double get categoryWeight => isSmallFisherman ? 1.0 : 0.5;

  bool get isSmallFisherman => fishermanTier.toLowerCase() == 'small';

  factory FishermanUser.fromJson(Map<String, dynamic> json) {
    return FishermanUser(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      nik: json['nik'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'fisherman',
      fishermanTier: json['fisherman_tier'] as String? ?? 'small',
      fcmToken: json['fcm_token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nik': nik,
      'phone': phone,
      'role': role,
      'fisherman_tier': fishermanTier,
      'fcm_token': fcmToken,
    };
  }

  FishermanUser copyWith({
    int? id,
    String? name,
    String? nik,
    String? phone,
    String? role,
    String? fishermanTier,
    String? fcmToken,
  }) {
    return FishermanUser(
      id: id ?? this.id,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      fishermanTier: fishermanTier ?? this.fishermanTier,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
