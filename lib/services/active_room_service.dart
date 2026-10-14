import 'package:flutter/foundation.dart';

import '../models/room.dart';

/// Menyimpan room terakhir yang PIN-nya berhasil diverifikasi, supaya pengguna
/// bisa masuk kembali ke ruang tunggu tanpa mengetik PIN lagi setelah keluar.
///
/// Hanya disimpan di memori (hilang saat app ditutup), karena JWT room dari
/// `POST /api/rooms/verify` hanya berlaku 1 jam. Saat masuk kembali, PIN
/// (`room.kode`) diverifikasi ulang untuk mendapat token yang masih segar.
class ActiveRoomService extends ChangeNotifier {
  ActiveRoomService._();
  static final ActiveRoomService instance = ActiveRoomService._();

  Room? _room;

  Room? get room => _room;
  bool get hasRoom => _room != null;

  void set(Room room) {
    _room = room;
    notifyListeners();
  }

  void clear() {
    if (_room == null) return;
    _room = null;
    notifyListeners();
  }
}
