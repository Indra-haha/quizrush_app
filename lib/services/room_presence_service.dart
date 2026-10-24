import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/room.dart';
import '../models/room_message.dart';
import 'active_room_service.dart';
import 'notification_service.dart';
import 'profile_settings_service.dart';
import 'session_service.dart';

typedef NotificationsEnabledReader = Future<bool> Function();

class RoomPresenceService with WidgetsBindingObserver {
  RoomPresenceService({
    ActiveRoomService? activeRoom,
    RoomNotificationGateway? notifications,
    NotificationsEnabledReader? notificationsEnabled,
    SessionService? session,
  })  : _activeRoom = activeRoom ?? ActiveRoomService.instance,
        _notifications = notifications ?? NotificationService.instance,
        _notificationsEnabled =
            notificationsEnabled ??
            ProfileSettingsService.instance.notificationsEnabled,
        _session = session ?? SessionService.instance;

  static final RoomPresenceService instance = RoomPresenceService();

  final ActiveRoomService _activeRoom;
  final RoomNotificationGateway _notifications;
  final NotificationsEnabledReader _notificationsEnabled;
  final SessionService _session;

  bool _started = false;
  bool _roomPageOpen = false;
  bool _appInForeground = true;

  Room? _activeRoomModel;
  dynamic _socket; // RoomSocket
  StreamSubscription<RoomMessage>? _messageSub;

  String _myUsername = '';
  String _myLabel = '';

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _activeRoom.addListener(_onActiveRoomChanged);
    _loadIdentity();
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _activeRoom.removeListener(_onActiveRoomChanged);
    _detachSocket();
    _activeRoomModel = null;
  }

  Future<void> _loadIdentity() async {
    final user = await _session.getUser();
    _myUsername = (user?['username'] as String?)?.trim() ?? '';
    _myLabel = (user?['nama'] as String?)?.trim() ?? '';
    if (_myLabel.isEmpty) _myLabel = _myUsername;
  }

  void setRoomPageOpen(bool open) {
    _roomPageOpen = open;
  }

  void setActiveSocket(dynamic socket, {required Room room}) {
    _activeRoomModel = room;
    _detachSocket();
    _socket = socket;
    if (_socket == null) return;
    try {
      final stream = (_socket as dynamic).messages;
      if (stream is Stream<RoomMessage>) {
        _messageSub = stream.listen(_onMessage);
      }
    } catch (_) {
      // ignore
    }
  }

  void _detachSocket() {
    _messageSub?.cancel();
    _messageSub = null;
    _socket = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appInForeground = true;
      return;
    }
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _appInForeground = false;
    }
  }

  void _onActiveRoomChanged() {
    final room = _activeRoom.room;
    if (room == null) {
      _detachSocket();
      _activeRoomModel = null;
      return;
    }
    _activeRoomModel = room;
  }

  void _onMessage(RoomMessage message) async {
    if (message.type != 'leave') return;
    final from = message.from.trim();
    if (from.isEmpty) return;

    // Don't notify self
    if (from == _myUsername || from == _myLabel) return;

    // If user still in waiting room and app foreground, don't notify (visible in UI)
    if (_roomPageOpen && _appInForeground) return;

    final room = _activeRoomModel ?? _activeRoom.room;
    if (room == null) return;

    if (!await _notificationsEnabled()) return;
    if (!await _notifications.isPermissionGranted()) return;

    final leaverName = from.isNotEmpty ? from : 'Seseorang';
    try {
      if (_notifications is NotificationService) {
        await (_notifications as NotificationService).showRoomLeaveNotification(
          leaverName: leaverName,
          roomCode: room.kode,
        );
        return;
      }
    } catch (_) {
      // fallback
    }

    // Fallback to generic reminder style if needed
    try {
      await _notifications.showRoomReminder(room);
    } catch (_) {}
  }
}
