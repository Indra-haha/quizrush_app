import 'dart:convert';

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
import 'package:quizrush/widgets/quiz_image_picker.dart';
import 'package:quizrush/widgets/quiz_question_editor.dart';
import 'package:quizrush/widgets/room_chat_bubble.dart';
import 'package:quizrush/widgets/room_composer.dart';
import 'package:quizrush/widgets/room_connection_bar.dart';
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

  group('QuizImagePicker', () {
    testWidgets('placeholder memanggil onPick saat ditekan', (
      WidgetTester tester,
    ) async {
      var picks = 0;
      await tester.pumpWidget(
        _wrap(
          QuizImagePicker(bytes: null, onPick: () => picks++, onRemove: () {}),
        ),
      );

      expect(
        find.text('Pilih Gambar (jpg, png, webp · maks 5 MB)'),
        findsOneWidget,
      );

      await tester.tap(find.byType(QuizImagePicker));
      expect(picks, 1);
    });

    testWidgets('mode picking menampilkan progres', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          QuizImagePicker(
            bytes: null,
            picking: true,
            onPick: () {},
            onRemove: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('pratinjau menampilkan tombol hapus yang memanggil onRemove', (
      WidgetTester tester,
    ) async {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      );
      var removes = 0;
      await tester.pumpWidget(
        _wrap(
          QuizImagePicker(
            bytes: bytes,
            onPick: () {},
            onRemove: () => removes++,
          ),
        ),
      );

      expect(find.byIcon(Icons.close), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close));
      expect(removes, 1);
    });
  });

  group('QuizQuestionEditor', () {
    void useTallView(WidgetTester tester) {
      tester.view.physicalSize = const Size(1200, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    QuizQuestionEditor build({
      int? correctIdx,
      VoidCallback? onRemove,
      ValueChanged<int>? onCorrect,
    }) {
      return QuizQuestionEditor(
        index: 0,
        questionController: TextEditingController(),
        optionControllers: List.generate(4, (_) => TextEditingController()),
        skorController: TextEditingController(),
        correctIdx: correctIdx,
        duration: 2,
        onCorrectChanged: onCorrect ?? (_) {},
        onDurationChanged: (_) {},
        onRemove: onRemove,
      );
    }

    testWidgets('menampilkan judul, durasi, dan poin', (
      WidgetTester tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(_wrap(build()));

      expect(find.text('Pertanyaan 1'), findsOneWidget);
      expect(find.text('Durasi'), findsOneWidget);
      expect(find.text('Poin (1-50)'), findsOneWidget);
    });

    testWidgets('menekan penanda jawaban meneruskan index', (
      WidgetTester tester,
    ) async {
      useTallView(tester);
      int? picked;
      await tester.pumpWidget(
        _wrap(build(correctIdx: 0, onCorrect: (index) => picked = index)),
      );

      await tester.tap(find.byIcon(Icons.check));
      expect(picked, 0);
    });

    testWidgets('tombol Hapus nonaktif tanpa onRemove', (
      WidgetTester tester,
    ) async {
      useTallView(tester);
      await tester.pumpWidget(_wrap(build()));

      final button = tester.widget<TextButton>(find.byType(TextButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tombol Hapus memanggil onRemove', (
      WidgetTester tester,
    ) async {
      useTallView(tester);
      var removed = 0;
      await tester.pumpWidget(_wrap(build(onRemove: () => removed++)));

      await tester.tap(find.text('Hapus'));
      expect(removed, 1);
    });
  });

  group('Widget ruang tunggu', () {
    testWidgets('RoomSystemMessage menampilkan teks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const RoomSystemMessage(text: 'bergabung.')));

      expect(find.text('bergabung.'), findsOneWidget);
    });

    testWidgets('RoomChatBubble menampilkan pengirim hanya untuk pesan orang lain', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const RoomChatBubble(from: 'Budi', text: 'halo', mine: false)),
      );

      expect(find.text('Budi'), findsOneWidget);
      expect(find.text('halo'), findsOneWidget);
    });

    testWidgets('RoomChatBubble milik sendiri menyembunyikan pengirim', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const RoomChatBubble(from: 'Kamu', text: 'hai', mine: true)),
      );

      expect(find.text('Kamu'), findsNothing);
      expect(find.text('hai'), findsOneWidget);
    });

    testWidgets('RoomConnectionBar menampilkan label, pemain, dan tombol retry', (
      WidgetTester tester,
    ) async {
      var retried = 0;
      await tester.pumpWidget(
        _wrap(
          RoomConnectionBar(
            statusColor: Colors.red,
            statusLabel: 'Koneksi terputus',
            users: 3,
            onRetry: () => retried++,
          ),
        ),
      );

      expect(find.text('Koneksi terputus'), findsOneWidget);
      expect(find.text('3 Pemain'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      expect(retried, 1);
    });

    testWidgets('RoomConnectionBar tanpa onRetry menyembunyikan tombol', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RoomConnectionBar(
            statusColor: Colors.green,
            statusLabel: 'Tersambung',
            users: 1,
          ),
        ),
      );

      expect(find.text('Coba lagi'), findsNothing);
    });

    testWidgets('RoomComposer mengirim saat aktif', (WidgetTester tester) async {
      var sent = 0;
      await tester.pumpWidget(
        _wrap(
          RoomComposer(
            controller: TextEditingController(),
            enabled: true,
            hintText: 'Tulis pesan...',
            onSend: () => sent++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.send));
      expect(sent, 1);
    });

    testWidgets('RoomComposer nonaktif tidak mengirim', (
      WidgetTester tester,
    ) async {
      var sent = 0;
      await tester.pumpWidget(
        _wrap(
          RoomComposer(
            controller: TextEditingController(),
            enabled: false,
            hintText: 'Menunggu koneksi...',
            onSend: () => sent++,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.send));
      expect(sent, 0);
    });
  });
}
