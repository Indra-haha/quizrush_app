/// Urutan publish room yang dipakai server dan label aksi berikutnya.
library;

import 'package:flutter/material.dart';

class RoomStatusFlow {
  RoomStatusFlow._();

  static const List<String> order = ['waiting', 'open', 'in-Game', 'ended'];

  /// Status berikutnya setelah [status], atau `null` kalau [status] sudah
  /// status terakhir atau tidak dikenal.
  static String? next(String status) {
    final idx = order.indexOf(status);
    if (idx < 0 || idx >= order.length - 1) return null;
    return order[idx + 1];
  }

  /// Label dan ikon tombol untuk memajukan status ke [next].
  static (String, IconData) publishMeta(String? next) {
    switch (next) {
      case 'open':
        return ('Publish', Icons.rocket_launch_outlined);
      case 'in-Game':
        return ('Mulai Game', Icons.play_circle_outline);
      case 'ended':
        return ('Akhiri', Icons.flag_outlined);
      default:
        return ('Selesai', Icons.check_circle_outline);
    }
  }
}
