/// Format slug wilayah dari `GET /api/location` menjadi label yang bisa
/// dibaca manusia.
///
/// Server mengirim slug administratif seperti `kecamatan-depok`,
/// `kota-sleman`, dan `provinsi-diy` (API.md §12). [formatRegionLabel]
/// membuang kata administratif yang berdiri sendiri, memformat setiap token
/// (huruf pertama kapital; token maksimal tiga huruf seperti `diy` menjadi
/// kapital semua), lalu menyambung ulang dengan spasi.
///
/// Contoh:
///
/// ```dart
/// formatRegionLabel('kecamatan-pasteur, kota-bandung, provinsi-jabar');
/// // 'Pasteur, kota Bandung, provinsi Jabar'
/// ```
String formatRegionLabel(String raw, {String separator = '-'}) {
  if (raw.trim().isEmpty) return '';

  final tokens = raw
      .split(separator)
      .map((token) => token.trim())
      .where((token) => token.isNotEmpty)
      .where((token) => !_administrativeWords.contains(token.toLowerCase()));

  return tokens.map(_capitalizeToken).join(' ');
}

/// Kata administratif yang dibuang dari label wilayah.
const _administrativeWords = <String>{
  'desa',
  'kecamatan',
  'kelurahan',
  'kabupaten',
  'kota',
  'provinsi',
};

/// Kapitalisasi satu token: huruf pertama kapital, sisanya dibiarkan apa
/// adanya. Token pendek (maksimal tiga huruf) jadi kapital semua supaya
/// singkatan seperti `diy` tetap terbaca sebagai `DIY`.
String _capitalizeToken(String token) {
  if (token.length <= 3) return token.toUpperCase();
  return token[0].toUpperCase() + token.substring(1);
}
