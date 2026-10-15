import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/helpers/json.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/models/room.dart';
import 'package:quizrush/models/room_message.dart';
import 'package:quizrush/models/room_verify.dart';
import 'package:quizrush/models/user.dart';

void main() {
  group('json helpers', () {
    test('jsonString hanya menerima String', () {
      expect(jsonString('a'), 'a');
      expect(jsonString(1), '');
      expect(jsonString(null, 'x'), 'x');
    });

    test('jsonStringOrNull mengembalikan null untuk bukan String', () {
      expect(jsonStringOrNull('a'), 'a');
      expect(jsonStringOrNull(1), isNull);
      expect(jsonStringOrNull(null), isNull);
    });

    test('jsonInt menerima num', () {
      expect(jsonInt(10), 10);
      expect(jsonInt(10.0), 10);
      expect(jsonInt(10.9), 10);
      expect(jsonInt('10'), 0);
      expect(jsonInt(null, 5), 5);
    });

    test('jsonDouble menerima int dan double', () {
      expect(jsonDouble(2), 2.0);
      expect(jsonDouble(1.5), 1.5);
      expect(jsonDouble('x', 3.0), 3.0);
    });

    test('jsonMap aman untuk bukan Map', () {
      expect(jsonMap({'a': 1}), {'a': 1});
      expect(jsonMap(null), isEmpty);
      expect(jsonMap('x'), isEmpty);
    });

    test('jsonStringList hanya menyaring String', () {
      expect(jsonStringList(['a', 1, 'b']), ['a', 'b']);
      expect(jsonStringList(null), isEmpty);
    });

    test('jsonMapList menormalkan tiap elemen', () {
      final result = jsonMapList([
        {'a': 1},
        'bukan-map',
      ]);
      expect(result, [
        {'a': 1},
      ]);
    });

    test('jsonObject membalas null untuk bukan Map', () {
      final quiz = jsonObject({'id': 'q1', 'title': 'Kuis'}, (m) {
        return QuizSummary.fromJson(m);
      });
      expect(quiz?.id, 'q1');
      expect(jsonObject(null, QuizSummary.fromJson), isNull);
    });
  });

  group('Quizes', () {
    test('fromJson mempertahankan path dan daftar bersarang', () {
      final quiz = Quizes.fromJson({
        'id': 'q1',
        'user_id': 'u1',
        'title': 'Kuis',
        'description': 'Deskripsi',
        'path': 'uploads/cover.png',
        'status': 'open',
        'created_at': '2026-09-17T10:00:00Z',
        'questions': [
          {'question': 'q', 'options': ['a', 'b'], 'duration': 2, 'skor': 10},
        ],
        'rooms': [
          {'id': 'r1', 'kode': '123456', 'status': 'waiting'},
        ],
      });

      expect(quiz.path, 'uploads/cover.png');
      expect(quiz.questions.single.skor, 10);
      expect(quiz.questions.single.duration, 2.0);
      expect(quiz.rooms.single.kode, '123456');
    });

    test('toJson/fromJson round-trip', () {
      const quiz = Quizes(
        id: 'q1',
        userId: 'u1',
        title: 'Kuis',
        description: 'Deskripsi',
        path: 'uploads/cover.png',
        createdAt: '2026-09-17T10:00:00Z',
        status: 'open',
        questions: [
          QuizQuestion(question: 'q', options: ['a', 'b'], duration: 1.5, skor: 5),
        ],
        rooms: [
          RoomSummary(id: 'r1', kode: '123456', status: 'waiting', createdAt: ''),
        ],
      );

      final kembali = Quizes.fromJson(quiz.toJson());
      expect(kembali.id, quiz.id);
      expect(kembali.path, quiz.path);
      expect(kembali.questions.single.skor, 5);
      expect(kembali.questions.single.duration, 1.5);
      expect(kembali.rooms.single.id, 'r1');
    });

    test('feed publik membaca ringkasan host & total tanpa soal mentah', () {
      final quiz = Quizes.fromJson({
        'id': 'q1',
        'host': 'Budi Santoso',
        'title': 'Kuis Mobile',
        'description': 'Dasar Flutter',
        'path': 'https://cdn/img.png',
        'total_questions': 10,
        'total_duration': 20,
        'total_skor': 200,
        'created_at': '2026-09-17T10:00:00Z',
        'rooms': [
          {'id': 'r1', 'judul': 'Room A', 'isi': 'Latihan', 'status': 'open'},
        ],
      });

      expect(quiz.host, 'Budi Santoso');
      expect(quiz.questions, isEmpty);
      expect(quiz.questionCount, 10);
      expect(quiz.durationSeconds, 20.0);
      expect(quiz.score, 200);
      expect(quiz.rooms.single.kode, isEmpty);
    });

    test('getter jatuh ke soal mentah saat ringkasan absen', () {
      const quiz = Quizes(
        id: 'q1',
        userId: 'u1',
        title: 'Kuis',
        description: '',
        createdAt: '',
        questions: [
          QuizQuestion(question: 'a', options: ['x'], duration: 1.5, skor: 5),
          QuizQuestion(question: 'b', options: ['y'], duration: 2, skor: 15),
        ],
      );

      expect(quiz.questionCount, 2);
      expect(quiz.durationSeconds, 3.5);
      expect(quiz.score, 20);
    });

    test('toJson tidak menulis soal/kode mentah saat kosong', () {
      const quiz = Quizes(
        id: 'q1',
        userId: '',
        host: 'Budi',
        title: 'Kuis',
        description: '',
        createdAt: '',
        questions: [],
        totalQuestions: 4,
        totalDuration: 8,
        totalSkor: 80,
      );

      final json = quiz.toJson();
      expect(json.containsKey('questions'), isFalse);
      expect(json.containsKey('user_id'), isFalse);
      expect(json['total_questions'], 4);
      expect(json['total_duration'], 8.0);
      expect(json['total_skor'], 80);
    });
  });

  group('MyQuizzes / AllQuizzes', () {
    test('menormalkan grup dari angka dan tipe salah', () {
      final mine = MyQuizzes.fromJson({
        'waiting': 'bukan-list',
        'open': [
          {'id': 'q1'},
        ],
      });
      expect(mine.open.length, 1);
      expect(mine.waiting, isEmpty);
      expect(mine.isEmpty, isFalse);
    });
  });

  group('Room', () {
    test('fromJson aman saat judul/isi null atau bukan String', () {
      final room = Room.fromJson({
        'id': 'r1',
        'quiz_id': 'q1',
        'kode': '123456',
        'status': 'waiting',
        'judul': 42,
        'isi': 'teks',
      });
      expect(room.judul, isNull);
      expect(room.isi, 'teks');
      expect(room.quiz, isNull);
    });

    test('toJson/fromJson round-trip', () {
      const room = Room(
        id: 'r1',
        quizId: 'q1',
        kode: '123456',
        status: 'waiting',
        createdAt: '2026-09-17T10:00:00Z',
        judul: 'Room A',
        quiz: QuizSummary(
          id: 'q1',
          title: 'Kuis',
          description: 'Deskripsi',
          totalQuestions: 5,
        ),
      );
      final kembali = Room.fromJson(room.toJson());
      expect(kembali.kode, '123456');
      expect(kembali.judul, 'Room A');
      expect(kembali.quiz?.totalQuestions, 5);
    });
  });

  group('RoomVerifyResult', () {
    test('aman saat room bukan Map', () {
      final result = RoomVerifyResult.fromJson({'token': 'jwt'});
      expect(result.token, 'jwt');
      expect(result.room.kode, '');
    });
  });

  group('User', () {
    test('toJson/fromJson round-trip', () {
      const user = User(
        username: 'budi',
        nama: 'Budi',
        kelas: '6A',
        tanggalLahir: '2005-03-05',
      );
      final kembali = User.fromJson(user.toJson());
      expect(kembali.username, 'budi');
      expect(kembali.nama, 'Budi');
      expect(kembali.kelas, '6A');
      expect(kembali.tanggalLahir, '2005-03-05');
    });
  });

  group('RoomMessage', () {
    test('fromJson aman untuk tipe salah', () {
      final message = RoomMessage.fromJson({
        'type': 'broadcast',
        'users': 3.0,
        'room': 99,
        'data': {'x': 1},
      });
      expect(message.type, 'broadcast');
      expect(message.users, 3);
      expect(message.room, '');
      expect(message.isBroadcast, isTrue);
    });

    test('isSystem benar untuk pesan sistem', () {
      expect(const RoomMessage(type: 'join').isSystem, isTrue);
      expect(const RoomMessage(type: 'echo').isSystem, isFalse);
    });
  });
}
