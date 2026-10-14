import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/models/room.dart';

Room _room({String? judul, QuizSummary? quiz}) {
  return Room(
    id: 'r1',
    quizId: 'q1',
    kode: '482913',
    status: 'waiting',
    createdAt: '2026-09-17T10:00:00Z',
    judul: judul,
    quiz: quiz,
  );
}

const _quiz = QuizSummary(
  id: 'q1',
  title: 'Kuis Pemrograman Mobile',
  description: 'Dasar Flutter & Dart',
  totalQuestions: 10,
);

void main() {
  group('Room.displayTitle', () {
    test('memakai judul room bila ada', () {
      expect(_room(judul: 'Room Soal Flutter').displayTitle, 'Room Soal Flutter');
    });

    test('jatuh ke judul kuis bila judul room kosong', () {
      expect(_room(quiz: _quiz).displayTitle, 'Kuis Pemrograman Mobile');
      expect(_room(judul: '', quiz: _quiz).displayTitle, 'Kuis Pemrograman Mobile');
    });

    test('jatuh ke default bila tidak ada judul sama sekali', () {
      expect(_room().displayTitle, 'Room Kuis');
      expect(_room(judul: '').displayTitle, 'Room Kuis');
    });
  });
}
