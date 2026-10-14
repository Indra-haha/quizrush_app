import 'dart:convert';

import 'package:http/http.dart' as http;

import 'device_service.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;

  const ApiException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  // Android emulator memakai 10.0.2.2 untuk mengakses localhost dari host.
  // Untuk device fisik, ganti dengan IP komputer (mis. https://192.168.1.10:8080).
  static const String baseUrl = 'https://deera-server.my.id';

  static Map<String, String> headers({String? token, bool body = false}) => {
    if (body) 'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
    'User-Agent': DeviceService.instance.userAgent,
  };

  static dynamic decode(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String message(dynamic data) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return 'Terjadi kesalahan';
  }
}
