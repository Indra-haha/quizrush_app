/// Validasi sederhana form login dan registrasi.
///
/// Mengembalikan pesan error pertama yang ditemukan, atau `null` kalau valid.
library;

class AuthValidator {
  AuthValidator._();

  /// Pesan error untuk form login, atau `null` kalau username dan password
  /// terisi.
  static String? login({required String username, required String password}) {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Username dan password wajib diisi';
    }
    return null;
  }

  /// Pesan error untuk form registrasi, atau `null` kalau semua field terisi
  /// dan password cocok dengan konfirmasinya.
  static String? register({
    required String nama,
    required String username,
    required String kelas,
    required String tanggalLahir,
    required String password,
    required String confirmPassword,
  }) {
    if (nama.trim().isEmpty ||
        username.trim().isEmpty ||
        kelas.trim().isEmpty ||
        tanggalLahir.trim().isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      return 'Semua field wajib diisi';
    }
    if (password != confirmPassword) {
      return 'Password tidak cocok';
    }
    return null;
  }
}
