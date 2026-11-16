/// Model akun pengguna aplikasi SiAntri Solar Nelayan
class UserAccount {
  final String id;
  final String nama;
  final String email;
  final String noHp;
  final String password;
  final String role; // 'nelayan' atau 'operator'
  final String? nomorRekomendasi; // Khusus nelayan (contoh: REK-DKP-2026-084)
  final String? kapasitasMesin; // Contoh: 'Mesin 10 PK - Maks. 30 Liter'

  const UserAccount({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.password,
    required this.role,
    this.nomorRekomendasi,
    this.kapasitasMesin,
  });

  bool get isOperator => role.toLowerCase() == 'operator';
  bool get isNelayan => role.toLowerCase() == 'nelayan';

  UserAccount copyWith({
    String? id,
    String? nama,
    String? email,
    String? noHp,
    String? password,
    String? role,
    String? nomorRekomendasi,
    String? kapasitasMesin,
  }) {
    return UserAccount(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      noHp: noHp ?? this.noHp,
      password: password ?? this.password,
      role: role ?? this.role,
      nomorRekomendasi: nomorRekomendasi ?? this.nomorRekomendasi,
      kapasitasMesin: kapasitasMesin ?? this.kapasitasMesin,
    );
  }
}
