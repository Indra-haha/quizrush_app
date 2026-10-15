import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_client.dart';
import 'device_service.dart';
import '../helpers/json.dart';
import '../models/user.dart';

class LoginResult {
  final String token;
  final Map<String, dynamic> user;

  const LoginResult({required this.token, required this.user});
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiClient.baseUrl}/api/login'),
          headers: ApiClient.headers(body: true),
          body: jsonEncode({
            'username': username,
            'password': password,
            'device_id': DeviceService.instance.getId(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return LoginResult(
      token: jsonString(data['token']),
      user: jsonMap(data['user']),
    );
  }

  Future<User> register({
    required String nama,
    required String username,
    required String kelas,
    required String tanggalLahir,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiClient.baseUrl}/api/register'),
          headers: ApiClient.headers(body: true),
          body: jsonEncode({
            'nama': nama,
            'username': username,
            'kelas': kelas,
            'tanggal_lahir': tanggalLahir,
            'password': password,
            'device_id': DeviceService.instance.getId(),
          }),
        )
        .timeout(const Duration(seconds: 10));

    final data = ApiClient.decode(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return User.fromJson(jsonMap(data['user']));
  }

  Future<void> logout(String token) async {
    final response = await http
        .post(
          Uri.parse('${ApiClient.baseUrl}/api/logout'),
          headers: ApiClient.headers(token: token),
        )
        .timeout(const Duration(seconds: 10));
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(ApiClient.decode(response)),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> checkSession(String token) async {
    final response = await http
        .get(
          Uri.parse('${ApiClient.baseUrl}/api/session'),
          headers: ApiClient.headers(token: token),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return jsonMap(data['user']);
  }
}
