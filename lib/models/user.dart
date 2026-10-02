class User {
  final String nim;
  final String nama;
  final String kelas;
  final String tanggalLahir;

  const User({
    required this.nim,
    required this.nama,
    required this.kelas,
    required this.tanggalLahir,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nim: json['nim'] as String? ?? '',
      nama: json['nama'] as String? ?? '',
      kelas: json['kelas'] as String? ?? '',
      tanggalLahir: json['tanggal_lahir'] as String? ?? '',
    );
  }
}
