import 'package:flutter/material.dart';

import '../pages/Quiz/waiting_room_page.dart';
import '../pages/login_page.dart';
import '../widgets/app_snackbar.dart';
import 'active_room_persistence_service.dart';
import 'active_room_service.dart';
import 'api/room_service.dart';
import 'app_navigator.dart';
import 'pending_room_service.dart';
import 'room_reminder_service.dart';
import 'session_service.dart';

/// Membuka kembali room dari notifikasi atau tombol aksi "Kembali ke Room".
class RoomNotificationRouter {
  RoomNotificationRouter._();

  static final RoomNotificationRouter instance = RoomNotificationRouter._();

  bool _opening = false;

  Future<void> openActiveRoom() async {
    if (_opening) return;

    final activeRoom = ActiveRoomService.instance;
    var room = activeRoom.room;

    // Halaman room masih terbuka di background; cukup resume aplikasi tanpa
    // membuat halaman duplikat.
    if (RoomReminderService.instance.roomPageOpen && room != null) {
      // try to ensure session
    }

    final navigator = await _waitForNavigator();
    if (navigator == null) return;

    _opening = true;
    try {
      // If we have full session, go directly
      if (room != null && activeRoom.hasRoomSession && activeRoom.roomToken != null && activeRoom.loginToken != null) {
        if (RoomReminderService.instance.roomPageOpen) {
          _opening = false;
          return;
        }
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WaitingRoomPage(
              room: room!,
              roomToken: activeRoom.roomToken!,
              loginToken: activeRoom.loginToken!,
            ),
          ),
        );
        _opening = false;
        return;
      }

      // Cold start / killed: try to restore from persistence
      if (room == null) {
        room = await ActiveRoomPersistenceService.instance.load();
        if (room != null) {
          activeRoom.set(room);
        }
      }

      if (room == null) {
        _opening = false;
        return;
      }

      if (RoomReminderService.instance.roomPageOpen) {
        _opening = false;
        return;
      }

      // Need to re-verify to get fresh roomToken
      final loginToken = await SessionService.instance.getToken();
      if (loginToken == null || loginToken.isEmpty) {
        _opening = false;
        try {
          await PendingRoomService.instance.setPending(room.kode);
        } catch (_) {}
        final nav = AppNavigator.key.currentState;
        if (nav != null) {
          nav.push(
            MaterialPageRoute<void>(builder: (_) => const LoginPage()),
          );
        } else {
          final context = AppNavigator.key.currentContext;
          if (context != null && context.mounted) {
            AppSnackBar.error(context, 'Silakan login untuk masuk kembali ke room.');
          }
        }
        return;
      }

      try {
        final verify = await RoomService.instance.verifyPin(
          token: loginToken,
          pin: room.kode,
        );
        activeRoom.set(verify.room, roomToken: verify.token, loginToken: loginToken);
        await navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => WaitingRoomPage(
              room: verify.room,
              roomToken: verify.token,
              loginToken: loginToken,
            ),
          ),
        );
        _opening = false;
        return;
      } catch (e) {
        _showError(
          e.toString().isEmpty ? 'Gagal membuka room. Coba lagi.' : e.toString(),
        );
        _opening = false;
        return;
      }
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
