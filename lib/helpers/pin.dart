/// Aturan PIN room: tepat enam digit angka.
library;

class Pin {
  Pin._();

  static const int length = 6;
  static final RegExp _complete = RegExp(r'^\d{6}$');
  static final RegExp _partial = RegExp(r'^\d{1,5}$');

  /// `true` kalau [value] (setelah trim) berupa PIN lengkap enam digit.
  static bool isComplete(String value) => _complete.hasMatch(value.trim());

  /// Jumlah digit PIN parsial (1-5) untuk umpan balik "mencari", atau `null`
  /// kalau [value] kosong, mengandung huruf, atau sudah enam digit.
  static int? progress(String value) {
    final query = value.trim();
    return _partial.hasMatch(query) ? query.length : null;
  }
}
