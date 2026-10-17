import '../helpers/json.dart';

/// Satu frame pesan JSON dari WebSocket room (API.md §9, "Format pesan").
///
/// `type` paling sering dipakai: dari server `connected`, `join`, `leave`,
/// `broadcast`; dari klien `ping`, `echo`, `count`, `broadcast`.
class RoomMessage {
  final String type;
  final String room;
  final String from;
  final String time;
  final int users;
  final Object? data;

  const RoomMessage({
    required this.type,
    this.room = '',
    this.from = '',
    this.time = '',
    this.users = 0,
    this.data,
  });

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      type: jsonString(json['type']),
      room: jsonString(json['room']),
      from: jsonString(json['from']),
      time: jsonString(json['time']),
      users: jsonInt(json['users']),
      data: json['data'],
    );
  }

  bool get isBroadcast => type == 'broadcast';
  bool get isSystem => type == 'connected' || type == 'join' || type == 'leave';
}
