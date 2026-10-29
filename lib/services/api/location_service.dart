import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/json.dart';
import '../../models/region_location.dart';
import 'api_client.dart';

/// Penyedia posisi perangkat; dapat diganti pada pengujian.
typedef PositionProvider = Future<Position?> Function();

/// Hasil permintaan akses lokasi perangkat.
enum LocationAccess {
  /// Izin diberikan (sekali pakai atau selalu).
  granted,

  /// Izin ditolak, masih bisa diminta ulang.
  denied,

  /// Izin ditolak permanen; perlu membuka pengaturan aplikasi.
  deniedForever,

  /// Layanan lokasi (GPS) perangkat dimatikan.
  serviceDisabled,

  /// Status tidak dapat ditentukan (mis. plugin tidak tersedia).
  unavailable,
}

/// Klien lokasi wilayah (`GET /api/location`, lihat API.md §12).
///
/// Mengambil koordinat GPS perangkat lalu mengirimnya ke server untuk
/// memperoleh wilayah terkini + opsi filter; hasil terakhir di-cache di
/// SharedPreferences agar halaman tetap menampilkan lokasi tanpa memanggil GPS.
class LocationService {
  LocationService._(this._api, this._positionProvider);

  /// Instance untuk pengujian dengan [ApiClient]/[PositionProvider] yang di-inject.
  LocationService.withApi(ApiClient api, {PositionProvider? positionProvider})
    : this._(api, positionProvider ?? devicePosition);

  static final LocationService instance = LocationService._(
    ApiClient.instance,
    devicePosition,
  );

  static const String _kCacheKey = 'region_location';
  static const String _kEnabledKey = 'region_location_enabled';
  static const int _kCacheVersion = 2;

  final ApiClient _api;
  final PositionProvider _positionProvider;

  /// Apakah fitur lokasi wilayah aktif.
  /// Mengembalikan true bila secara eksplisit diaktifkan atau cache sudah pernah ada.
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final explicit = prefs.getBool(_kEnabledKey);
    if (explicit != null) return explicit;
    return prefs.containsKey(_kCacheKey);
  }

  /// Aktifkan atau nonaktifkan fitur lokasi wilayah.
  /// Bila dinonaktifkan, cache dihapus agar halaman peringkat tidak menampilkan lokasi lama.
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, enabled);
    if (!enabled) {
      await clearCache();
    }
  }

  /// Hapus cache lokasi wilayah.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCacheKey);
  }

  /// Kirim koordinat user; respons berisi metadata wilayah + grouped
  /// leaderboard (kecamatan/kota/provinsi). Seluruh respons disimpan utuh.
  Future<LocationResult> submit({
    required String token,
    required double latitude,
    required double longitude,
    double? accuracy,
  }) async {
    final response = await _api.get(
      '/api/location?latitude=$latitude&longitude=$longitude',
      token: token,
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    final result = LocationResult.fromJson(jsonMap(data));
    await _writeCache(result);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEnabledKey, true);
    return result;
  }

  /// Alur lengkap GPS → kirim. `null` bila izin ditolak atau lokasi tak tersedia.
  Future<LocationResult?> locate({required String token}) async {
    try {
      final position = await _positionProvider();
      if (position == null) return null;
      return await submit(
        token: token,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
      );
    } catch (_) {
      return null;
    }
  }

  /// Hasil lokasi terakhir dari cache (tanpa GPS maupun server). Mendukung
  /// cache versi lama (respons mentah) maupun cache versi baru (tersimpan utuh).
  Future<LocationResult?> readCached() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kEnabledKey) == false) return null;
    final raw = prefs.getString(_kCacheKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final map = decoded.cast<String, dynamic>();
        if (map.containsKey('result')) {
          return LocationResult.fromJson(jsonMap(map['result']));
        }
        // Cache lama: seluruh respons API disimpan mentah.
        return LocationResult.fromJson(map);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _writeCache(LocationResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCacheKey,
      jsonEncode({
        'version': _kCacheVersion,
        'savedAt': DateTime.now().toIso8601String(),
        'result': result.toJson(),
      }),
    );
  }

  /// Cek izin lokasi dan status GPS saat ini tanpa menampilkan dialog izin ke pengguna.
  static Future<LocationAccess> checkCurrentPermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceDisabled;
      }
      final permission = await Geolocator.checkPermission();
      switch (permission) {
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationAccess.granted;
        case LocationPermission.deniedForever:
          return LocationAccess.deniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationAccess.denied;
      }
    } catch (_) {
      return LocationAccess.unavailable;
    }
  }

  /// Minta akses lokasi: cek layanan GPS, izin tersimpan, lalu ajukan izin
  /// bila perlu. Selalu mengembalikan status agar UI dapat memandu user.
  static Future<LocationAccess> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationAccess.serviceDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.whileInUse:
        case LocationPermission.always:
          return LocationAccess.granted;
        case LocationPermission.deniedForever:
          return LocationAccess.deniedForever;
        case LocationPermission.denied:
        case LocationPermission.unableToDetermine:
          return LocationAccess.denied;
      }
    } catch (_) {
      return LocationAccess.unavailable;
    }
  }

  /// Buka halaman pengaturan aplikasi (untuk izin yang ditolak permanen).
  static Future<bool> openSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }

  /// Ambil posisi perangkat sekali pakai; `null` bila layanan lokasi mati,
  /// izin ditolak, atau pengambilan gagal.
  static Future<Position?> devicePosition() async {
    try {
      final access = await ensurePermission();
      if (access != LocationAccess.granted) return null;
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return last;
      } catch (_) {}
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 4),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
