class User {
  final String username;
  final String nama;
  final String kelas;
  final String tanggalLahir;

  const User({
    required this.username,
    required this.nama,
    required this.kelas,
    required this.tanggalLahir,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      kelas: json['kelas'] as String? ?? '',
      tanggalLahir: json['tanggal_lahir'] as String? ?? '',
    );
  }
}
