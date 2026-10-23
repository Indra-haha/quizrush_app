import 'package:flutter/foundation.dart';

import '../models/room.dart';

/// Menyimpan room terakhir yang PIN-nya berhasil diverifikasi, supaya pengguna
/// bisa masuk kembali ke ruang tunggu tanpa mengetik PIN lagi setelah keluar.
///
/// Room, token room, dan token login disimpan di memori. Token room dari
/// `POST /api/rooms/verify` hanya berlaku 1 jam, jadi data ini hilang saat app
/// ditutup dan PIN perlu diverifikasi ulang untuk mendapatkan token baru.
class ActiveRoomService extends ChangeNotifier {
  ActiveRoomService._();
  static final ActiveRoomService instance = ActiveRoomService._();

  Room? _room;
  String? _roomToken;
  String? _loginToken;

  Room? get room => _room;
  bool get hasRoom => _room != null;

  /// JWT ber-scope room dari `POST /api/rooms/verify`, dipakai untuk membuka
  /// kembali [WaitingRoomPage] dari aksi notifikasi tanpa verifikasi PIN.
  String? get roomToken => _roomToken;

  /// JWT login yang dipakai sebagai header WebSocket room.
  String? get loginToken => _loginToken;

  bool get hasRoomSession =>
      _room != null && _roomToken != null && _loginToken != null;

  void set(Room room, {String? roomToken, String? loginToken}) {
    _room = room;
    _roomToken = roomToken;
    _loginToken = loginToken;
    notifyListeners();
  }

  /// Perbarui data room (mis. setelah status berubah) tanpa menghapus token.
  void updateRoom(Room room) {
    if (_room == null) return;
    _room = room;
    notifyListeners();
  }

  void clear() {
    if (_room == null && _roomToken == null && _loginToken == null) return;
    _room = null;
    _roomToken = null;
    _loginToken = null;
    notifyListeners();
  }
}
