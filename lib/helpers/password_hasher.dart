import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Menghasilkan hash SHA-256 (hex lowercase) dari password plaintext.
///
/// Password selalu dikirim ke server dalam bentuk hash ini, bukan plaintext,
/// sehingga aman walaupun request melewati jaringan. Pengiriman tetap
/// menggunakan HTTPS untuk melindungi token dan data lainnya.
String hashPassword(String plain) {
  return sha256.convert(utf8.encode(plain)).toString();
}
