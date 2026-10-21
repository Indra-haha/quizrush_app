import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/json.dart';
import '../models/region_location.dart';
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

/// Klien lokasi wilayah (template `POST /api/location`, lihat API.md §12).
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

  final ApiClient _api;
  final PositionProvider _positionProvider;

  /// Kirim koordinat user; respons berisi wilayah terkini + opsi filter.
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
    await _writeCache(data);
    return LocationResult.fromJson(jsonMap(data));
  }

  /// Alur lengkap GPS → kirim. `null` bila izin ditolak atau lokasi tak tersedia.
  Future<LocationResult?> locate({required String token}) async {
    final position = await _positionProvider();
    if (position == null) return null;
    return submit(
      token: token,
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
    );
  }

  /// Hasil lokasi terakhir dari cache (tanpa GPS maupun server).
  Future<LocationResult?> readCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCacheKey);
    if (raw == null) return null;
    try {
      return LocationResult.fromJson(jsonMap(jsonDecode(raw)));
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeCache(dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCacheKey, jsonEncode(data));
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
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
