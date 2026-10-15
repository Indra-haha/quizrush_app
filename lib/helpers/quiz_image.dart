/// Aturan gambar sampul kuis: batas ukuran, nama file, dan tipe media.
library;

import 'package:http_parser/http_parser.dart';

class QuizImage {
  QuizImage._();

  static const int maxBytes = 5 * 1024 * 1024;

  static bool isWithinSizeLimit(int byteLength) => byteLength <= maxBytes;

  /// Nama file untuk multipart: pakai [name] kalau ada, jatuh ke segmen
  /// terakhir [path].
  static String filename({required String name, required String path}) {
    if (name.trim().isNotEmpty) return name;
    return path.split(RegExp(r'[\\/]')).last;
  }

  /// Tipe media berdasarkan ekstensi [filename].
  static MediaType mediaType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
