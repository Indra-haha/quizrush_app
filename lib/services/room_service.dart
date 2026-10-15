import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../helpers/json.dart';
import '../models/room.dart';
import '../models/room_verify.dart';
import 'api_client.dart';

class RoomService {
  RoomService._();
  static final RoomService instance = RoomService._();

  /// Verifikasi 6 digit PIN room (API.md §5.3 `POST /api/rooms/verify`).
  ///
  /// Berhasil (200) mengembalikan JWT ber-scope room + data room; token itulah
  /// yang lalu dipakai sebagai query `token` untuk handshake WebSocket
  /// `GET /api/rooms?token=<JWT room>` (API.md §8.1).
  Future<RoomVerifyResult> verifyPin({
    required String token,
    required String pin,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiClient.baseUrl}/api/rooms/verify'),
          headers: ApiClient.headers(token: token, body: true),
          body: jsonEncode({'pin': pin}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return RoomVerifyResult.fromJson(jsonMap(data));
  }

  Future<Room> createRoom({
    required String token,
    required String quizId,
    String? judul,
    String? isi,
    String? status,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiClient.baseUrl}/api/create/room'),
          headers: ApiClient.headers(token: token, body: true),
          body: jsonEncode({
            'quiz_id': quizId,
            'judul': ?judul,
            'isi': ?isi,
            'status': ?status,
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 201) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Room.fromJson(jsonMap(data['room']));
  }

  Future<Room> updateRoomStatus({
    required String token,
    required String roomId,
    required String status,
  }) async {
    final response = await http
        .put(
          Uri.parse('${ApiClient.baseUrl}/api/room/$roomId/status'),
          headers: ApiClient.headers(token: token, body: true),
          body: jsonEncode({'room_id': roomId, 'status': status}),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Room.fromJson(jsonMap(data['room']));
  }
}
