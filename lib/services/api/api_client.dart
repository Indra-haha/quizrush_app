import 'dart:convert';

import 'package:http/http.dart' as http;

import '../device_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}

/// Pembungkus HTTP tunggal untuk semua service.
///
/// [http.Client] dan [baseUrl] bisa diganti (mis. `MockClient` dan server lokal
/// pada pengujian) sehingga service tidak lagi memanggil fungsi global
/// `http.get`/`http.post` langsung. Gunakan [ApiClient.instance] di produksi,
/// atau `ApiClient(client: ..., baseUrl: ...)` di test.
class ApiClient {
  ApiClient({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      baseUrl = baseUrl ?? defaultBaseUrl;

  static const String defaultBaseUrl = 'https://deera-server.my.id';
  static const Duration defaultTimeout = Duration(seconds: 10);

  static final ApiClient instance = ApiClient();

  final http.Client _client;
  final String baseUrl;

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Map<String, String> headers({String? token, bool body = false}) => {
    if (body) 'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    'User-Agent': DeviceService.instance.userAgent,
  };

  Future<http.Response> get(
    String path, {
    String? token,
    Duration timeout = defaultTimeout,
  }) {
    return _client
        .get(uri(path), headers: headers(token: token))
        .timeout(timeout);
  }

  Future<http.Response> post(
    String path, {
    String? token,
    Object? body,
    Duration timeout = defaultTimeout,
  }) {
    return _client
        .post(
          uri(path),
          headers: headers(token: token, body: body != null),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  Future<http.Response> put(
    String path, {
    String? token,
    Object? body,
    Duration timeout = defaultTimeout,
  }) {
    return _client
        .put(
          uri(path),
          headers: headers(token: token, body: body != null),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  Future<http.Response> patch(
    String path, {
    String? token,
    Object? body,
    Duration timeout = defaultTimeout,
  }) {
    return _client
        .patch(
          uri(path),
          headers: headers(token: token, body: body != null),
          body: body == null ? null : jsonEncode(body),
        )
        .timeout(timeout);
  }

  /// Kirim [request] mentah (mis. `MultipartRequest`) memakai client ini.
  Future<http.Response> send(
    http.BaseRequest request, {
    Duration timeout = defaultTimeout,
  }) async {
    final streamed = await _client.send(request).timeout(timeout);
    return http.Response.fromStream(streamed);
  }

  static dynamic decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Pesan kesalahan dari body JSON. Bila body bukan JSON (mis. halaman HTML
  /// dari proxy/nginx saat timeout), dipakai pesan berbasis [statusCode] agar
  /// pengguna tidak hanya melihat "Terjadi kesalahan".
  static String message(dynamic data, {int? statusCode}) {
    if (data is Map) {
      if (data['message'] is String && (data['message'] as String).isNotEmpty) {
        return data['message'] as String;
      }
      if (data['error'] is String && (data['error'] as String).isNotEmpty) {
        return data['error'] as String;
      }
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Terjadi kesalahan pada server (HTTP $statusCode)';
    }
    return 'Terjadi kesalahan';
  }
}
