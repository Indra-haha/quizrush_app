import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/services/quiz_cache_service.dart';
import 'package:quizrush/services/quiz_index.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> quizJson(
  String id,
  String title,
  List<Map<String, dynamic>> rooms,
) {
  return {
    'id': id,
    'user_id': 'u1',
    'title': title,
    'description': '',
    'created_at': '2026-09-20T08:00:00Z',
    'rooms': rooms,
    'questions': [
      {
        'question': '1 + 1 = ?',
        'options': ['1', '2', '3', '4'],
        'duration': 2,
        'skor': 10,
      },
    ],
  };
}

Map<String, dynamic> roomJson(String id, String kode, String status) {
  return {
    'id': id,
    'kode': kode,
    'status': status,
    'judul': 'Room $kode',
    'isi': '',
    'created_at': '2026-09-20T09:00:00Z',
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('QuizCacheService', () {
    test('readAll balas null saat cache belum pernah diisi', () async {
      expect(await QuizCacheService.instance.readAll(), isNull);
      expect(await QuizCacheService.instance.readMine(), isNull);
    });

    test('cache kosong dari server tetap tersimpan sebagai kosong', () async {
      await QuizCacheService.instance.saveAllQuizzes(const AllQuizzes());

      final cache = await QuizCacheService.instance.readAll();
      expect(cache, isNotNull);
      expect(cache!.isEmpty, isTrue);
    });

    test('AllQuizzes hanya menyimpan tiga grup', () async {
      final data = AllQuizzes.fromJson({
        'waiting': [
          quizJson('q1', 'Kuis Menunggu', [
            roomJson('r1', '111111', 'waiting'),
          ]),
        ],
        'open': [quizJson('q2', 'Kuis Matematika', [])],
        'in-Game': [quizJson('q3', 'Kuis Fisika', [])],
        'ended': [quizJson('q4', 'Kuis Kimia', [])],
        'quarantine': [quizJson('q5', 'Kuis Baru', [])],
      });
      expect(data.all.map((q) => q.id), ['q2', 'q3', 'q4']);

      await QuizCacheService.instance.saveAllQuizzes(data);
      final cache = await QuizCacheService.instance.readAll();
      expect(cache!.all.map((q) => q.id), ['q2', 'q3', 'q4']);
      expect(cache.groups.keys, ['open', 'in-Game', 'ended']);
    });

    test('tiga grup AllQuizzes tersimpan utuh setelah round-trip', () async {
      final data = AllQuizzes.fromJson({
        'open': [
          quizJson('q2', 'Kuis Matematika', [roomJson('r2', '482913', 'open')]),
        ],
        'in-Game': [
          quizJson('q3', 'Kuis Fisika', [roomJson('r3', '222222', 'in-Game')]),
        ],
        'ended': [
          quizJson('q4', 'Kuis Kimia', [roomJson('r4', '333333', 'ended')]),
        ],
      });
      await QuizCacheService.instance.saveAllQuizzes(data);

      final cache = await QuizCacheService.instance.readAll();
      expect(cache, isNotNull);
      expect(cache!.all, hasLength(3));
      expect(cache.groups['open'], ['q2']);
      expect(cache.groups['in-Game'], ['q3']);
      expect(cache.groups['ended'], ['q4']);
      expect(cache.savedAt.millisecondsSinceEpoch, greaterThan(0));
    });

    test('lima grup MyQuizzes tersimpan utuh setelah round-trip', () async {
      final data = MyQuizzes.fromJson({
        'waiting': [
          quizJson('q1', 'Kuis Menunggu', [
            roomJson('r1', '111111', 'waiting'),
          ]),
        ],
        'open': [
          quizJson('q2', 'Kuis Matematika', [roomJson('r2', '482913', 'open')]),
        ],
        'in-Game': [
          quizJson('q3', 'Kuis Fisika', [roomJson('r3', '222222', 'in-Game')]),
        ],
        'ended': [
          quizJson('q4', 'Kuis Kimia', [roomJson('r4', '333333', 'ended')]),
        ],
        'quarantine': [quizJson('q5', 'Kuis Baru', [])],
      });
      await QuizCacheService.instance.saveMyQuizzes(data);

      final cache = await QuizCacheService.instance.readMine();
      expect(cache, isNotNull);
      expect(cache!.all, hasLength(5));
      expect(cache.groups['waiting'], ['q1']);
      expect(cache.groups['open'], ['q2']);
      expect(cache.groups['in-Game'], ['q3']);
      expect(cache.groups['ended'], ['q4']);
      expect(cache.groups['quarantine'], ['q5']);
    });

    test('quiz dirantai ke user lain tidak ikut kebaca', () async {
      await QuizCacheService.instance.saveAllQuizzes(
        AllQuizzes.fromJson({
          'open': [quizJson('q1', 'Kuis Matematika', [])],
        }),
      );

      // Login sebagai username berbeda: cache sebelumnya tidak boleh terlihat.
      SharedPreferences.setMockInitialValues({
        'auth_user': jsonEncode({'username': '999', 'nama': 'Budi'}),
      });
      expect(await QuizCacheService.instance.readAll(), isNull);
    });

    test('cache versi lama (flat list) dimigrasi ke format per grup', () async {
      SharedPreferences.setMockInitialValues({
        'cache_all-guest': jsonEncode([
          quizJson('q1', 'Kuis Matematika', [roomJson('r1', '482913', 'open')]),
          quizJson('q2', 'Kuis Baru', []),
        ]),
      });

      final cache = await QuizCacheService.instance.readAll();
      expect(cache, isNotNull);
      expect(cache!.all, hasLength(2));
      expect(cache.groups['open'], ['q1']);
      expect(cache.groups['quarantine'], ['q2']);
    });

    test('clear menghapus seluruh kunci cache', () async {
      await QuizCacheService.instance.saveAllQuizzes(const AllQuizzes());
      await QuizCacheService.instance.saveMyQuizzes(const MyQuizzes());
      await QuizCacheService.instance.clear();

      expect(await QuizCacheService.instance.readAll(), isNull);
      expect(await QuizCacheService.instance.readMine(), isNull);
    });
  });

  group('QuizIndex', () {
    late QuizIndex index;

    setUp(() async {
      await QuizCacheService.instance.saveMyQuizzes(
        MyQuizzes.fromJson({
          'waiting': [
            quizJson('q1', 'Kuis Matematika Dasar', [
              roomJson('r1', '111111', 'waiting'),
            ]),
          ],
          'open': [
            quizJson('q2', 'Matematika Lanjut', [
              roomJson('r2', '482913', 'open'),
            ]),
            quizJson('q3', 'Basis Data MongoDB', [
              roomJson('r3', '654321', 'open'),
            ]),
          ],
          'in-Game': [
            quizJson('q4', 'Fisika Modern', [
              roomJson('r4', '222222', 'in-Game'),
            ]),
          ],
          'ended': [],
          'quarantine': [quizJson('q5', 'Kuis Tanpa Room', [])],
        }),
      );
      final cache = await QuizCacheService.instance.readMine();
      index = QuizIndex.fromCache(cache!);
    });

    test('filter per grup status', () {
      expect(index.group('open').map((q) => q.id), ['q2', 'q3']);
      expect(index.group('waiting').map((q) => q.id), ['q1']);
      expect(index.group('in-Game').map((q) => q.id), ['q4']);
      expect(index.group('ended'), isEmpty);
    });

    test('cari PIN menemukan room dan kuisnya', () {
      final found = index.findRoomByKode('482913');
      expect(found, isNotNull);
      expect(found!.quiz.id, 'q2');
      expect(found.room.id, 'r2');
    });

    test('cari PIN di status waiting tetap ketemu', () {
      final found = index.findRoomByKode('111111');
      expect(found?.quiz.id, 'q1');
    });

    test('cari PIN yang tidak ada mengembalikan null', () {
      expect(index.findRoomByKode('000000'), isNull);
    });

    test('cari judul memakai awal kata pertama', () {
      // "Kuis Matematika Dasar" tidak ikut: "mat" bukan awal kata pertama.
      expect(index.search('mat').map((q) => q.id), ['q2']);
      expect(index.search('kuis').map((q) => q.id), contains('q1'));
      expect(index.search('basis').map((q) => q.id), ['q3']);
      expect(index.search('fisika').map((q) => q.id), ['q4']);
    });

    test('cari judul mengabaikan huruf besar dan spasi', () {
      expect(index.search('  MATEMATIKA  ').map((q) => q.id), ['q2']);
    });

    test('kata di tengah judul tidak cocok', () {
      expect(index.search('baru'), isEmpty);
      expect(index.search('mongo'), isEmpty);
    });

    test('PIN sebagian tidak menyaring daftar', () {
      expect(index.search('482'), isEmpty);
      expect(index.search('65'), isEmpty);
      expect(index.search('482913').map((q) => q.id), isEmpty);
    });

    test('kueri kosong mengembalikan semua kuis', () {
      expect(index.search(''), hasLength(5));
      expect(index.isEmpty, isFalse);
    });
  });
}
