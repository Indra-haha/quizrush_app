import '../helpers/json.dart';

class User {
  final String username;
  final String nama;
  final String kelas;
  final String tanggalLahir;
  final String? urlImg;

  const User({
    required this.username,
    required this.nama,
    required this.kelas,
    required this.tanggalLahir,
    this.urlImg,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: jsonString(json['username']),
      nama: jsonString(json['nama']),
      kelas: jsonString(json['kelas']),
      tanggalLahir: jsonString(json['tanggal_lahir']),
      urlImg: json['url_img'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nama': nama,
      'kelas': kelas,
      'tanggal_lahir': tanggalLahir,
      if (urlImg != null) 'url_img': urlImg,
    };
  }

  User copyWith({
    String? username,
    String? nama,
    String? kelas,
    String? tanggalLahir,
    String? urlImg,
  }) {
    return User(
      username: username ?? this.username,
      nama: nama ?? this.nama,
      kelas: kelas ?? this.kelas,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      urlImg: urlImg ?? this.urlImg,
    );
  }
}
