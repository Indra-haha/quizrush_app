import 'package:shared_preferences/shared_preferences.dart';

class PendingRoomService {
  PendingRoomService._();
  static final PendingRoomService instance = PendingRoomService._();

  static const _kPending = 'pending_room_code';

  Future<void> setPending(String roomCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPending, roomCode.trim());
  }

  Future<String?> getPending() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_kPending);
    if (code == null || code.trim().isEmpty) return null;
    return code.trim();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPending);
  }
}
