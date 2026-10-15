import '../helpers/json.dart';
import 'room.dart';

/// Hasil `POST /api/rooms/verify` (API.md §5.3): JWT ber-scope room untuk
/// handshake WebSocket (`GET /api/rooms?token=...`) plus data room-nya.
class RoomVerifyResult {
  final String token;
  final Room room;

  const RoomVerifyResult({required this.token, required this.room});

  factory RoomVerifyResult.fromJson(Map<String, dynamic> json) {
    return RoomVerifyResult(
      token: jsonString(json['token']),
      room: Room.fromJson(jsonMap(json['room'])),
    );
  }
}
