import 'package:flutter/material.dart';

import '../pages/Quiz/waiting_room_page.dart';
import '../pages/login_redirect.dart';
import '../services/active_room_service.dart';
import '../services/api/room_service.dart';
import '../services/session_service.dart';

/// Alur bersama untuk masuk ke ruang tunggu, dipakai halaman input PIN maupun
/// tombol "Masuk Room" di daftar kuis:
///
/// 1. ambil token login (redirect ke login bila tidak ada);
/// 2. verifikasi PIN ke `POST /api/rooms/verify` (`RoomService.verifyPin`);
///   * catat room sebagai aktif lewat [ActiveRoomService];
///   * buka [WaitingRoomPage] (`push`, atau `pushReplacement` bila [replace]).
///
/// `ApiException` dari verifikasi sengaja dibiarkan naik supaya tiap halaman
/// bisa menampilkan error dengan gayanya sendiri (inline vs snackbar).
class RoomLauncher {
  RoomLauncher._();

  static Future<void> enter({
    required BuildContext context,
    required String pin,
    bool replace = false,
  }) async {
    final token = await SessionService.instance.getToken();
    if (!context.mounted) return;
    if (token == null || token.isEmpty) {
      LoginRedirect.go(context);
      return;
    }

    final result = await RoomService.instance.verifyPin(
      token: token,
      pin: pin,
    );
    ActiveRoomService.instance.set(result.room);
    if (!context.mounted) return;

    final route = MaterialPageRoute<void>(
      builder: (_) => WaitingRoomPage(
        room: result.room,
        roomToken: result.token,
        loginToken: token,
      ),
    );
    if (replace) {
      await Navigator.of(context).pushReplacement(route);
    } else {
      await Navigator.of(context).push(route);
    }
  }
}
