import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/helpers/quiz_play_session.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/theme/quiz_status.dart';
import 'package:quizrush/widgets/app_pill.dart';
import 'package:quizrush/widgets/app_primary_button.dart';
import 'package:quizrush/widgets/app_stat_tile.dart';
import 'package:quizrush/widgets/cache_info_bar.dart';
import 'package:quizrush/widgets/empty_state_view.dart';
import 'package:quizrush/widgets/quiz_answer_banner.dart';
import 'package:quizrush/widgets/quiz_countdown_dial.dart';
import 'package:quizrush/widgets/status_filter_row.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

QuizQuestion _question({
  double duration = 2,
  int skor = 0,
  List<String>? options,
}) {
  return QuizQuestion(
    question: '2 + 2 = ?',
    options: options ?? ['4', '3', '5', '6'],
    duration: duration,
    skor: skor,
  );
}

void main() {
  group('AppPill', () {
    testWidgets('menampilkan teks utama, teks ekor, dan titik', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppPill(
            text: 'Soal 1',
            trailingText: '/ 4',
            background: Colors.white,
            foreground: Colors.black,
            dot: Colors.blue,
          ),
        ),
      );

      expect(find.text('Soal 1'), findsOneWidget);
      expect(find.text('/ 4'), findsOneWidget);
    });

    testWidgets('roomStatus memakai label dari QuizStatus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(AppPill.roomStatus('in-Game')));

      expect(find.text(QuizStatus.labelOf('in-Game')), findsOneWidget);
    });
  });

  group('StatusFilterRow', () {
    testWidgets('chip sesuai status dan meneruskan pilihan', (
      WidgetTester tester,
    ) async {
      String? picked;
      await tester.pumpWidget(
        _wrap(
          StatusFilterRow(
            statuses: const ['open', 'ended'],
            selected: 'open',
            onChanged: (status) => picked = status,
          ),
        ),
      );

      expect(find.text(QuizStatus.labelOf('open')), findsOneWidget);
      expect(find.text(QuizStatus.labelOf('ended')), findsOneWidget);

      await tester.tap(find.text(QuizStatus.labelOf('ended')));
      expect(picked, 'ended');
    });
  });

  group('CacheInfoBar', () {
    testWidgets('mode progres PIN', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const CacheInfoBar(pinProgress: 3)));

      expect(find.text('PIN room: 3 dari 6 digit.'), findsOneWidget);
    });

    testWidgets('mode waktu cache disembunyikan tanpa savedAt', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const CacheInfoBar()));

      expect(find.byType(Text), findsNothing);
    });
  });

  group('AppPrimaryButton', () {
    testWidgets('menonaktifkan tombol saat loading', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AppPrimaryButton(
            label: 'Kirim',
            loading: true,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('memanggil onPressed saat aktif', (WidgetTester tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(AppPrimaryButton(label: 'Kirim', onPressed: () => taps++)),
      );

      await tester.tap(find.byType(FilledButton));
      expect(taps, 1);
    });
  });

  group('EmptyStateView', () {
    testWidgets('variant notFound menampilkan pesan dan caption', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const EmptyStateView.notFound()));

      expect(find.text('Room tidak ditemukan'), findsOneWidget);
      expect(find.text('Tekan refresh bila room baru dibuat.'), findsOneWidget);
    });
  });

  group('AppStatTile.compact', () {
    testWidgets('menampilkan nilai dengan warna yang diminta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const AppStatTile.compact(
            value: '120',
            bg: Colors.orange,
            fg: Colors.black,
          ),
        ),
      );

      expect(find.text('120'), findsOneWidget);
    });
  });

  group('Widget halaman test quiz', () {
    testWidgets('dial menampilkan sisa detik', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuizCountdownDial(seconds: 7)));
      expect(find.text('7'), findsOneWidget);
      expect(find.text('DETIK'), findsOneWidget);
    });

    testWidgets('banner benar menampilkan poin yang didapat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizAnswerBanner(isCorrect: true, gainedScore: 25)),
      );

      expect(find.text('Kamu Benar! (+25 Poin)'), findsOneWidget);
    });

    testWidgets('banner salah tidak menampilkan poin', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizAnswerBanner(isCorrect: false, gainedScore: 0)),
      );

      expect(find.text('Kamu Salah! (+0 Poin)'), findsOneWidget);
    });
  });

  group('QuizStatus.palette', () {
    test('setiap status punya warna dan label', () {
      for (final status in const [
        'waiting',
        'open',
        'in-Game',
        'ended',
        'quarantine',
      ]) {
        expect(QuizStatus.palette(status).bg, isNotNull);
        expect(QuizStatus.palette(status).fg, isNotNull);
        expect(QuizStatus.labelOf(status), isNotEmpty);
      }
    });
  });

  group('QuizPlaySession', () {
    test('soal kosong tidak memulai sesi', () {
      final session = QuizPlaySession(questions: const []);
      session.start();

      expect(session.isEmpty, isTrue);
      session.dispose();
    });

    test('durasi dan poin maksimum memakai fallback', () {
      final session = QuizPlaySession(
        questions: [_question(duration: 0, skor: 0)],
      )..start();

      expect(session.maxDuration, session.defaultDuration);
      expect(session.currentMaxScore, 50);
      expect(session.timeLeft, session.defaultDuration.toInt());
      session.dispose();
    });

    test('menjawab benar menambah skor dan mengunci jawaban', () {
      final session = QuizPlaySession(
        questions: [_question(duration: 5, skor: 50)],
        feedbackDelay: Duration.zero,
      )..start();

      session.answer(0);
      expect(session.isAnswered, isTrue);
      expect(session.isUserCorrect, isTrue);
      expect(session.selectedAnswerIndex, 0);
      expect(session.gainedScore, greaterThan(0));
      expect(session.totalScore, session.gainedScore);

      final gained = session.gainedScore;
      session.answer(1);
      expect(session.gainedScore, gained, reason: 'jawaban kedua diabaikan');
      session.dispose();
    });

    test('menjawab salah tidak menambah skor', () {
      final session = QuizPlaySession(
        questions: [_question(duration: 5, skor: 50)],
        feedbackDelay: Duration.zero,
      )..start();

      session.answer(2);

      expect(session.isUserCorrect, isFalse);
      expect(session.gainedScore, 0);
      expect(session.totalScore, 0);
      session.dispose();
    });

    test('advance pindah soal lalu bersihkan state jawaban', () {
      final session = QuizPlaySession(
        questions: [_question(), _question(duration: 3)],
        feedbackDelay: Duration.zero,
      )..start();

      session.answer(0);
      session.advance();

      expect(session.currentIndex, 1);
      expect(session.isAnswered, isFalse);
      expect(session.selectedAnswerIndex, isNull);
      expect(session.isUserCorrect, isNull);
      expect(session.gainedScore, 0);
      expect(session.totalScore, greaterThan(0));
      session.dispose();
    });

    test('soal terakhir memanggil onFinished', () {
      var finished = false;
      final session =
          QuizPlaySession(
              questions: [_question()],
              feedbackDelay: Duration.zero,
            )
            ..onFinished = () {
              finished = true;
            };
      session.start();

      session.answer(0);
      session.advance();

      expect(finished, isTrue);
      session.dispose();
    });

    test('onChanged dipanggil saat timer dan jawaban berubah', () {
      var changes = 0;
      final session =
          QuizPlaySession(
              questions: [_question(duration: 5, skor: 50)],
              feedbackDelay: Duration.zero,
            )
            ..onChanged = () {
              changes++;
            };
      session.start();

      expect(changes, 0, reason: 'start belum mengubah state');

      session.answer(0);
      expect(changes, 1);
      session.dispose();
    });
  });
}
