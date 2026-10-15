import 'api_client.dart';
import 'device_service.dart';
import '../helpers/json.dart';
import '../helpers/password_hasher.dart';
import '../models/user.dart';

class LoginResult {
  final String token;
  final Map<String, dynamic> user;

  const LoginResult({required this.token, required this.user});
}

class AuthService {
  AuthService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  AuthService.withApi(this._api);

  static final AuthService instance = AuthService._(ApiClient.instance);

  final ApiClient _api;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) {
    return loginWithHash(username: username, passwordHash: hashPassword(password));
  }

  /// Login memakai password yang sudah di-hash SHA-256.
  ///
  /// Dipakai login biometrik: kredensial tersimpan langsung dikirim tanpa
  /// di-hash ulang.
  Future<LoginResult> loginWithHash({
    required String username,
    required String passwordHash,
  }) async {
    final response = await _api.post(
      '/api/login',
      body: {
        'username': username,
        'password': passwordHash,
        'device_id': DeviceService.instance.getId(),
      },
    );

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
    final response = await _api.post(
      '/api/register',
      body: {
        'nama': nama,
        'username': username,
        'kelas': kelas,
        'tanggal_lahir': tanggalLahir,
        'password': hashPassword(password),
        'device_id': DeviceService.instance.getId(),
      },
    );

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
    final response = await _api.post('/api/logout', token: token);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(ApiClient.decode(response)),
        statusCode: response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> checkSession(String token) async {
    final response = await _api.get('/api/session', token: token);
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
