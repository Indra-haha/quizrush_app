/// Satu frame pesan JSON dari WebSocket room (API.md §8, "Format pesan").
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
      type: json['type'] as String? ?? '',
      room: json['room'] as String? ?? '',
      from: json['from'] as String? ?? '',
      time: json['time'] as String? ?? '',
      users: (json['users'] as num?)?.toInt() ?? 0,
      data: json['data'],
    );
  }

  bool get isBroadcast => type == 'broadcast';
  bool get isSystem => type == 'connected' || type == 'join' || type == 'leave';
}
