import '../helpers/json.dart';

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
      username: jsonString(json['username']),
      nama: jsonString(json['nama']),
      kelas: jsonString(json['kelas']),
      tanggalLahir: jsonString(json['tanggal_lahir']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nama': nama,
      'kelas': kelas,
      'tanggal_lahir': tanggalLahir,
    };
  }
}
