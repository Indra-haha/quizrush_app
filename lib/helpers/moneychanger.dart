/// Helper konversi mata uang dengan tabel kurs statis berbasis Rupiah.
///
/// Nilai pada [_ratesToIdr] adalah jumlah Rupiah untuk 1 unit mata uang.
/// Kurs bersifat perkiraan dan tidak real-time; perbarui tabel ini bila perlu.
///
/// Contoh:
///
/// ```dart
/// convertMoney(162500, 'IDR', 'USD'); // 10.0
/// formatMoney(10, 'USD');             // '\$ 10,00'
/// ```
library;

/// Kurs terhadap Rupiah: 1 unit mata uang = sekian Rupiah.
const Map<String, double> _ratesToIdr = <String, double>{
  'IDR': 1,
  'USD': 16300,
  'EUR': 17800,
  'SGD': 12100,
  'MYR': 3700,
  'JPY': 105,
  'GBP': 20700,
  'AUD': 10700,
  'CNY': 2250,
};

/// Simbol yang dipakai saat memformat nilai.
const Map<String, String> _symbols = <String, String>{
  'IDR': 'Rp',
  'USD': r'$',
  'EUR': '€',
  'SGD': r'S$',
  'MYR': 'RM',
  'JPY': '¥',
  'GBP': '£',
  'AUD': r'A$',
  'CNY': 'CN¥',
};

/// Jumlah digit desimal saat memformat nilai.
const Map<String, int> _decimals = <String, int>{
  'IDR': 0,
  'USD': 2,
  'EUR': 2,
  'SGD': 2,
  'MYR': 2,
  'JPY': 0,
  'GBP': 2,
  'AUD': 2,
  'CNY': 2,
};

/// Daftar kode mata uang yang didukung.
List<String> get supportedCurrencies => List.unmodifiable(_ratesToIdr.keys);

/// Normalisasi kode mata uang: trim, huruf besar, dan `Rp` dianggap `IDR`.
String _normalize(String code) {
  final upper = code.trim().toUpperCase();
  return upper == 'RP' ? 'IDR' : upper;
}

double _rateFor(String code) {
  final normalized = _normalize(code);
  final rate = _ratesToIdr[normalized];
  if (rate == null) {
    throw ArgumentError.value(code, 'currency', 'Mata uang tidak didukung');
  }
  return rate;
}

/// Mengonversi [value] dari mata uang [from] ke mata uang [to].
///
/// Kode mata uang tidak peka huruf besar/kecil; `Rp` diperlakukan sama
/// dengan `IDR`. Melempar [ArgumentError] jika salah satu kode tidak dikenal.
///
/// ```dart
/// convertMoney(163000, 'IDR', 'USD'); // 10.0
/// convertMoney(10, 'USD', 'IDR');     // 163000.0
/// convertMoney(10, 'USD', 'SGD');     // 13.471...
/// ```
double convertMoney(double value, String from, String to) {
  final fromRate = _rateFor(from);
  final toRate = _rateFor(to);
  return value * fromRate / toRate;
}

/// Memformat [value] sebagai uang dalam [currently] atau dikonversi ke [future].
///
/// Jika [future] disertakan, [value] dikonversi dari mata uang [currently] ke [future]
/// sebelum diformat dengan simbol dan aturan desimal milik [future].
///
/// Pemisah ribuan memakai titik dan desimal memakai koma (gaya Indonesia).
/// `IDR` dan `JPY` ditampilkan tanpa desimal; mata uang lain dua desimal.
///
/// ```dart
/// formatMoney(284500, 'IDR');         // 'Rp 284.500'
/// formatMoney(18.5, 'USD');           // '\$ 18,50'
/// formatMoney(43434, 'IDR', 'USD');   // '\$ 2,66'
/// ```
String formatMoney(num value, String currently, [String? future]) {
  final target =
      (future != null && future.trim().isNotEmpty) ? future : currently;
  final fromNorm = _normalize(currently);
  final toNorm = _normalize(target);

  final valDouble = value.toDouble();
  final converted = (fromNorm == toNorm)
      ? valDouble
      : convertMoney(valDouble, fromNorm, toNorm);

  final decimals = _decimals[toNorm] ?? 2;
  final negative = converted < 0;
  final fixed = converted.abs().toStringAsFixed(decimals);
  final parts = fixed.split('.');
  final digits = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  final grouped = parts.length > 1 && decimals > 0
      ? '$buffer,${parts[1]}'
      : buffer.toString();
  final symbol = _symbols[toNorm] ?? toNorm;
  return '${negative ? '-' : ''}$symbol $grouped';
}
