import '../../helpers/json.dart';
import '../../models/room.dart';
import '../../models/room_verify.dart';
import 'api_client.dart';

class RoomService {
  RoomService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  RoomService.withApi(this._api);

  static final RoomService instance = RoomService._(ApiClient.instance);

  final ApiClient _api;

  /// Verifikasi 6 digit PIN room (API.md §5.3 `POST /api/rooms/verify`).
  ///
  /// Berhasil (200) mengembalikan JWT ber-scope room + data room; token itulah
  /// yang lalu dipakai sebagai query `token` untuk handshake WebSocket
  /// `GET /api/rooms?token=<JWT room>` (API.md §9.1).
  Future<RoomVerifyResult> verifyPin({
    required String token,
    required String pin,
  }) async {
    final response = await _api.post(
      '/api/rooms/verify',
      token: token,
      body: {'pin': pin},
    );
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
    String? type,
  }) async {
    final response = await _api.post(
      '/api/create/room',
      token: token,
      body: {
        'quiz_id': quizId,
        'judul': ?judul,
        'isi': ?isi,
        'status': ?status,
        'type': ?type,
      },
    );
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
    final response = await _api.put(
      '/api/room/$roomId/status',
      token: token,
      body: {'room_id': roomId, 'status': status},
    );
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
