/// Parser JSON defensif yang dipakai semua model.
///
/// Server boleh mengirim angka sebagai `num` (`10` atau `10.0`) dan field
/// opsional bisa `null`; helper di sini menjaga `fromJson` tidak pernah
/// melempar `_TypeError` karena bentuk data yang berbeda.
library;

String jsonString(Object? value, [String fallback = '']) {
  return value is String ? value : fallback;
}

String? jsonStringOrNull(Object? value) {
  return value is String ? value : null;
}

int jsonInt(Object? value, [int fallback = 0]) {
  return value is num ? value.toInt() : fallback;
}

double jsonDouble(Object? value, [double fallback = 0]) {
  return value is num ? value.toDouble() : fallback;
}

Map<String, dynamic> jsonMap(Object? value) {
  return value is Map ? value.cast<String, dynamic>() : const {};
}

List<String> jsonStringList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}

List<Map<String, dynamic>> jsonMapList(Object? value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
}

/// Parse objek bersarang; balas `null` kalau `value` bukan `Map`.
T? jsonObject<T>(Object? value, T Function(Map<String, dynamic>) parse) {
  return value is Map ? parse(value.cast<String, dynamic>()) : null;
}
