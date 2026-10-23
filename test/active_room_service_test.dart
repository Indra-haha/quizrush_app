import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/models/room.dart';
import 'package:quizrush/services/active_room_service.dart';

Room _room({String status = 'waiting'}) => Room(
  id: 'r1',
  quizId: 'q1',
  kode: '482913',
  status: status,
  createdAt: '2026-09-17T10:00:00Z',
);

void main() {
  final service = ActiveRoomService.instance;

  tearDown(service.clear);

  test('awalnya tidak ada room aktif', () {
    expect(service.hasRoom, isFalse);
    expect(service.room, isNull);
  });

  test('set menyimpan room dan memberi notifikasi', () {
    var notified = 0;
    void listener() => notified++;
    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    service.set(_room());

    expect(service.hasRoom, isTrue);
    expect(service.room?.kode, '482913');
    expect(notified, 1);
  });

  test('set menyimpan token room dan token login', () {
    service.set(_room(), roomToken: 'room-token', loginToken: 'login-token');

    expect(service.hasRoomSession, isTrue);
    expect(service.roomToken, 'room-token');
    expect(service.loginToken, 'login-token');
  });

  test('updateRoom mempertahankan token dan memperbarui status', () {
    service.set(_room(), roomToken: 'room-token', loginToken: 'login-token');

    service.updateRoom(_room(status: 'open'));

    expect(service.room?.status, 'open');
    expect(service.roomToken, 'room-token');
    expect(service.loginToken, 'login-token');
  });

  test('clear menghapus room dan memberi notifikasi', () {
    service.set(_room(), roomToken: 'room-token', loginToken: 'login-token');

    var notified = 0;
    void listener() => notified++;
    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    service.clear();

    expect(service.hasRoom, isFalse);
    expect(service.room, isNull);
    expect(service.roomToken, isNull);
    expect(service.loginToken, isNull);
    expect(service.hasRoomSession, isFalse);
    expect(notified, 1);
  });

  test('clear saat kosong tidak memberi notifikasi', () {
    var notified = 0;
    void listener() => notified++;
    service.addListener(listener);
    addTearDown(() => service.removeListener(listener));

    service.clear();

    expect(notified, 0);
  });
}
