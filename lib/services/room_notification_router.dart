import 'package:flutter/material.dart';

import '../helpers/room_launcher.dart';
import '../pages/Quiz/waiting_room_page.dart';
import '../widgets/app_snackbar.dart';
import 'active_room_service.dart';
import 'app_navigator.dart';
import 'room_reminder_service.dart';

/// Membuka kembali room dari notifikasi atau tombol aksi "Kembali ke Room".
class RoomNotificationRouter {
  RoomNotificationRouter._();

  static final RoomNotificationRouter instance = RoomNotificationRouter._();

  bool _opening = false;

  Future<void> openActiveRoom() async {
    if (_opening) return;

    final activeRoom = ActiveRoomService.instance;
    final room = activeRoom.room;
    if (room == null) return;

    // Halaman room masih terbuka di background; cukup resume aplikasi tanpa
    // membuat halaman duplikat.
    if (RoomReminderService.instance.roomPageOpen) return;

    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    _opening = true;
    try {
      if (activeRoom.hasRoomSession) {
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WaitingRoomPage(
              room: room,
              roomToken: activeRoom.roomToken!,
              loginToken: activeRoom.loginToken!,
            ),
          ),
        );
        return;
      }

      final context = AppNavigator.key.currentContext;
      if (context == null || !context.mounted) return;
      await RoomLauncher.enter(context: context, pin: room.kode);
    } catch (e) {
      _showError(
        e.toString().isEmpty ? 'Gagal membuka room. Coba lagi.' : e.toString(),
      );
    } finally {
      _opening = false;
    }
  }

  void _showError(String message) {
    final context = AppNavigator.key.currentContext;
    if (context == null) return;
    AppSnackBar.error(context, message);
  }

  Future<NavigatorState?> _waitForNavigator() async {
    var navigator = AppNavigator.key.currentState;
    for (var attempt = 0; navigator == null && attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      navigator = AppNavigator.key.currentState;
    }
    return navigator;
  }
}
