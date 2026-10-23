import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/models/room.dart';
import 'package:quizrush/services/active_room_service.dart';
import 'package:quizrush/services/notification_service.dart';
import 'package:quizrush/services/room_reminder_service.dart';

class _FakeNotifications implements RoomNotificationGateway {
  bool permissionGranted = true;
  int shows = 0;
  int cancels = 0;

  @override
  Future<bool> isPermissionGranted() async => permissionGranted;

  @override
  Future<void> showRoomReminder(Room room) async {
    shows++;
  }

  @override
  Future<void> cancelRoomReminder() async {
    cancels++;
  }
}

const _room = Room(
  id: 'r1',
  quizId: 'q1',
  kode: '482913',
  status: 'waiting',
  createdAt: '2026-09-17T10:00:00Z',
);

RoomReminderService _service(
  _FakeNotifications notifications, {
  bool enabled = true,
}) {
  return RoomReminderService(
    notifications: notifications,
    notificationsEnabled: () async => enabled,
    leaveDebounce: Duration.zero,
  );
}

Future<void> _flush() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final activeRoom = ActiveRoomService.instance;

  setUp(activeRoom.clear);
  tearDown(activeRoom.clear);

  test('membuka halaman room membatalkan notifikasi', () async {
    final notifications = _FakeNotifications();
    final service = _service(notifications);
    activeRoom.set(_room, roomToken: 'room-token', loginToken: 'login-token');

    service.onRoomPageOpened();
    await _flush();

    expect(service.roomPageOpen, isTrue);
    expect(notifications.cancels, 1);
    expect(notifications.shows, 0);
  });

  test('meninggalkan halaman room menampilkan notifikasi', () async {
    final notifications = _FakeNotifications();
    final service = _service(notifications);
    activeRoom.set(_room, roomToken: 'room-token', loginToken: 'login-token');
    service.onRoomPageOpened();

    service.onRoomPageClosed();
    await _flush();

    expect(service.roomPageOpen, isFalse);
    expect(notifications.shows, 1);
  });

  test('masuk background saat room aktif menampilkan notifikasi', () async {
    final notifications = _FakeNotifications();
    final service = _service(notifications);
    activeRoom.set(_room, roomToken: 'room-token', loginToken: 'login-token');
    service.onRoomPageOpened();

    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await _flush();

    expect(notifications.shows, 1);
  });

  test('tidak menampilkan notifikasi saat preferensi mati', () async {
    final notifications = _FakeNotifications();
    final service = _service(notifications, enabled: false);
    activeRoom.set(_room, roomToken: 'room-token', loginToken: 'login-token');

    service.onRoomPageClosed();
    await _flush();

    expect(notifications.shows, 0);
  });

  test('tidak menampilkan notifikasi tanpa izin OS', () async {
    final notifications = _FakeNotifications()..permissionGranted = false;
    final service = _service(notifications);
    activeRoom.set(_room, roomToken: 'room-token', loginToken: 'login-token');

    service.onRoomPageClosed();
    await _flush();

    expect(notifications.shows, 0);
  });

  test('tidak menampilkan notifikasi tanpa room aktif', () async {
    final notifications = _FakeNotifications();
    final service = _service(notifications);

    service.onRoomPageClosed();
    await _flush();

    expect(notifications.shows, 0);
  });

  test('melepas room membatalkan notifikasi', () async {
    final notifications = _FakeNotifications();
    final service = _service(notifications);
    service.start();
    addTearDown(service.stop);
    activeRoom.set(_room, roomToken: 'room-token', loginToken: 'login-token');
    service.onRoomPageOpened();
    notifications.cancels = 0;

    activeRoom.clear();
    await _flush();

    expect(notifications.cancels, 1);
  });
}
