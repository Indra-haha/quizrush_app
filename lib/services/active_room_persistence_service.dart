import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/room.dart';

class ActiveRoomPersistenceService {
  ActiveRoomPersistenceService._();
  static final ActiveRoomPersistenceService instance =
      ActiveRoomPersistenceService._();

  static const _kRoom = 'active_room_json';

  Future<void> save(Room room) async {
    final prefs = await SharedPreferences.getInstance();
    final map = room.toJson();
    await prefs.setString(_kRoom, jsonEncode(map));
  }

  Future<Room?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRoom);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return Room.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRoom);
  }
}
