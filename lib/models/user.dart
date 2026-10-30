import '../helpers/json.dart';

class User {
  final String username;
  final String nama;
  final String sekolah;
  final String tanggalLahir;
  final String? urlImg;

  const User({
    required this.username,
    required this.nama,
    required this.sekolah,
    required this.tanggalLahir,
    this.urlImg,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final school = json['sekolah'] ?? json['kelas'];
    return User(
      username: jsonString(json['username']),
      nama: jsonString(json['nama']),
      sekolah: jsonString(school),
      tanggalLahir: jsonString(json['tanggal_lahir']),
      urlImg: json['url_img'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'nama': nama,
      'sekolah': sekolah,
      'tanggal_lahir': tanggalLahir,
      if (urlImg != null) 'url_img': urlImg,
    };
  }

  User copyWith({
    String? username,
    String? nama,
    String? sekolah,
    String? tanggalLahir,
    String? urlImg,
  }) {
    return User(
      username: username ?? this.username,
      nama: nama ?? this.nama,
      sekolah: sekolah ?? this.sekolah,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      urlImg: urlImg ?? this.urlImg,
    );
  }
}
