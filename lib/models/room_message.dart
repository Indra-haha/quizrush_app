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

  /// Daftar nickname klien yang sudah terhubung saat pesan `connected`
  /// dikirim server (API.md §9.1); kosong untuk tipe pesan lain.
  final List<String> names;

  const RoomMessage({
    required this.type,
    this.room = '',
    this.from = '',
    this.time = '',
    this.users = 0,
    this.data,
    this.names = const [],
  });

  factory RoomMessage.fromJson(Map<String, dynamic> json) {
    return RoomMessage(
      type: jsonString(json['type']),
      room: jsonString(json['room']),
      from: jsonString(json['from']),
      time: jsonString(json['time']),
      users: jsonInt(json['users']),
      data: json['data'],
      names: jsonStringList(json['names']),
    );
  }

  bool get isBroadcast => type == 'broadcast';
  bool get isSystem => type == 'connected' || type == 'join' || type == 'leave';
}
