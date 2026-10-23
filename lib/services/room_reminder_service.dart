import 'dart:async';

import 'package:flutter/widgets.dart';

import 'active_room_service.dart';
import 'notification_service.dart';
import 'profile_settings_service.dart';

typedef NotificationsEnabledReader = Future<bool> Function();

/// Memutuskan kapan pengingat room ditampilkan:
/// * saat aplikasi masuk background selama room masih aktif;
/// * saat pengguna meninggalkan halaman ruang tunggu tetapi room belum
///   dilepas.
///
/// Notifikasi yang sama selalu memakai satu ID di [NotificationService],
/// sehingga kejadian beruntun hanya mengganti notifikasi lama.
class RoomReminderService with WidgetsBindingObserver {
  RoomReminderService({
    ActiveRoomService? activeRoom,
    RoomNotificationGateway? notifications,
    NotificationsEnabledReader? notificationsEnabled,
    this._leaveDebounce = const Duration(milliseconds: 350),
  }) : _activeRoom = activeRoom ?? ActiveRoomService.instance,
       _notifications = notifications ?? NotificationService.instance,
       _notificationsEnabled =
           notificationsEnabled ??
           ProfileSettingsService.instance.notificationsEnabled;

  static final RoomReminderService instance = RoomReminderService();

  final ActiveRoomService _activeRoom;
  final RoomNotificationGateway _notifications;
  final NotificationsEnabledReader _notificationsEnabled;
  final Duration _leaveDebounce;

  bool _started = false;
  bool _roomPageOpen = false;
  bool _appInForeground = true;
  bool _notifying = false;
  Timer? _leaveTimer;

  bool get roomPageOpen => _roomPageOpen;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _activeRoom.addListener(_onActiveRoomChanged);
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _activeRoom.removeListener(_onActiveRoomChanged);
    _leaveTimer?.cancel();
  }

  /// Dipanggil oleh `WaitingRoomPage` saat halaman room mulai tampil.
  void onRoomPageOpened() {
    _roomPageOpen = true;
    _leaveTimer?.cancel();
    unawaited(_notifications.cancelRoomReminder());
  }

  /// Dipanggil oleh `WaitingRoomPage` saat halaman room ditutup.
  void onRoomPageClosed() {
    _roomPageOpen = false;
    _leaveTimer?.cancel();
    _leaveTimer = Timer(_leaveDebounce, () {
      unawaited(_notifyIfNeeded());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appInForeground = true;
      unawaited(_notifications.cancelRoomReminder());
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _appInForeground = false;
      unawaited(_notifyIfNeeded());
    }
  }

  Future<void> _notifyIfNeeded() async {
    if (_notifying) return;

    final room = _activeRoom.room;
    if (room == null) return;
    if (_appInForeground && _roomPageOpen) return;
    if (!await _notificationsEnabled()) return;
    if (!await _notifications.isPermissionGranted()) return;

    if (_notifying) return;
    _notifying = true;
    try {
      await _notifications.showRoomReminder(room);
    } finally {
      _notifying = false;
    }
  }

  void _onActiveRoomChanged() {
    if (_activeRoom.room != null) return;
    _leaveTimer?.cancel();
    unawaited(_notifications.cancelRoomReminder());
  }
}
