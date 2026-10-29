import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/helpers/quiz_play_session.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/theme/quiz_status.dart';
import 'package:quizrush/widgets/app_pill.dart';
import 'package:quizrush/widgets/app_bottom_sheet.dart';
import 'package:quizrush/widgets/app_primary_button.dart';
import 'package:quizrush/widgets/app_stat_tile.dart';
import 'package:quizrush/widgets/auth_fields.dart';
import 'package:quizrush/widgets/cache_info_bar.dart';
import 'package:quizrush/widgets/empty_state_view.dart';
import 'package:quizrush/widgets/enter_pin_intro_card.dart';
import 'package:quizrush/widgets/home_stat_card.dart';
import 'package:quizrush/widgets/load_more_button.dart';
import 'package:quizrush/widgets/pin_input_field.dart';
import 'package:quizrush/widgets/quiz_answer_banner.dart';
import 'package:quizrush/widgets/quiz_card.dart';
import 'package:quizrush/widgets/quiz_countdown_dial.dart';
import 'package:quizrush/widgets/quiz_detail_hero.dart';
import 'package:quizrush/widgets/quiz_image_picker.dart';
import 'package:quizrush/widgets/quiz_question_editor.dart';
import 'package:quizrush/widgets/quiz_question_preview.dart';
import 'package:quizrush/widgets/quiz_question_card.dart';
import 'package:quizrush/widgets/quiz_results_list.dart';
import 'package:quizrush/widgets/quiz_search_field.dart';
import 'package:quizrush/widgets/quiz_test_header.dart';
import 'package:quizrush/widgets/room_chat_bubble.dart';
import 'package:quizrush/widgets/room_composer.dart';
import 'package:quizrush/widgets/room_connection_bar.dart';
import 'package:quizrush/widgets/room_code_dialog.dart';
import 'package:quizrush/widgets/room_detail_card.dart';
import 'package:quizrush/widgets/room_list_header.dart';
import 'package:quizrush/widgets/room_list_tile.dart';
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

Quizes _quiz({List<RoomSummary> rooms = const []}) {
  return Quizes(
    id: 'q1',
    userId: 'u1',
    title: 'Kuis Matematika',
    description: 'Latihan cepat',
    createdAt: '2026-09-17T10:00:00Z',
    questions: [_question()],
    rooms: rooms,
  );
}

RoomSummary _room({String status = 'open'}) {
  return RoomSummary(
    id: 'r1',
    kode: '123456',
    status: status,
    createdAt: '2026-09-17T10:00:00Z',
    judul: 'Room Seru',
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

    testWidgets('mode uploading menampilkan overlay progres dengan label', (
      WidgetTester tester,
    ) async {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      );
      await tester.pumpWidget(
        _wrap(
          QuizImagePicker(
            bytes: bytes,
            uploading: true,
            uploadLabel: 'Minta signature ke server…',
            onPick: () {},
            onRemove: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Minta signature ke server…'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('mode error menampilkan tombol Coba lagi yang memanggil onRetry', (
      WidgetTester tester,
    ) async {
      final bytes = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
      );
      var retries = 0;
      await tester.pumpWidget(
        _wrap(
          QuizImagePicker(
            bytes: bytes,
            uploadError: true,
            onPick: () {},
            onRemove: () {},
            onRetry: () => retries++,
          ),
        ),
      );

      expect(find.text('Gagal mengunggah'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
      await tester.tap(find.text('Coba lagi'));
      expect(retries, 1);
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
      expect(find.text('Poin'), findsOneWidget);
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

  group('Widget detail room', () {
    testWidgets('QuizQuestionPreviewCard menampilkan soal, poin, dan opsi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          QuizQuestionPreviewCard(
            question: _question(skor: 10),
            index: 0,
          ),
        ),
      );

      expect(find.text('Soal 1'), findsOneWidget);
      expect(find.text('2 + 2 = ?'), findsOneWidget);
      expect(find.text('10 Pts'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('LoadMoreButton menampilkan sisa dan memanggil onTap', (
      WidgetTester tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          LoadMoreButton(total: 5, remaining: 2, onTap: () => tapped++),
        ),
      );

      expect(find.text('Muat 2 Soal Lainnya (Total 5 Soal)'), findsOneWidget);

      await tester.tap(find.byType(LoadMoreButton));
      expect(tapped, 1);
    });
  });

  group('Widget quiz page', () {
    testWidgets('QuizSearchField menampilkan hint dan refresh', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          QuizSearchField(
            controller: TextEditingController(),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('QuizResultsList menampilkan loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          QuizResultsList(
            error: null,
            notFound: false,
            pinProgress: null,
            quizzes: const [],
            query: '',
            onTapQuiz: (_) {},
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('RoomCodeDialog', () {
    testWidgets('menampilkan kode room yang dibuat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showRoomCodeDialog(context, '123456'),
                child: const Text('buka'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();

      expect(find.text('Room Dibuat'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
    });
  });

  group('Widget beranda', () {
    testWidgets('HomeStatCard menampilkan label dan nilai', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HomeStatCard(
            label: 'Total Main',
            value: '1.2k',
            icon: Icons.sports_esports,
          ),
        ),
      );

      expect(find.text('Total Main'), findsOneWidget);
      expect(find.text('1.2k'), findsOneWidget);
    });
    testWidgets('QuizCard varian home memakai kategori default', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 350,
            child: QuizCard(
              quiz: _quiz(),
              style: QuizCardStyle.home,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Umum'), findsOneWidget);
      expect(find.text('1 Soal'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });
  });

  group('Widget detail quiz room', () {
    testWidgets('QuizDetailHero menampilkan judul, deskripsi, dan tipe', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(QuizDetailHero(quiz: _quiz())));

      expect(find.text('Kuis Matematika'), findsOneWidget);
      expect(find.text('Latihan cepat'), findsOneWidget);
      expect(find.text('Pilihan Ganda'), findsOneWidget);
    });

    testWidgets('RoomListHeader menampilkan jumlah room', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const RoomListHeader(count: 3)));

      expect(find.text('Daftar Room'), findsOneWidget);
      expect(find.text('3 Room'), findsOneWidget);
    });

    testWidgets('RoomDetailCard menampilkan PIN dan tombol Masuk', (
      WidgetTester tester,
    ) async {
      var joined = 0;
      await tester.pumpWidget(
        _wrap(
          RoomDetailCard(
            room: _room(),
            index: 0,
            isFocused: false,
            onJoin: () => joined++,
          ),
        ),
      );

      expect(find.text('123 456'), findsOneWidget);
      expect(find.text('Room Seru'), findsOneWidget);

      await tester.tap(find.text('Masuk'));
      expect(joined, 1);
    });

    testWidgets('RoomDetailCard fokus menampilkan pill PIN', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          RoomDetailCard(room: _room(), index: 0, isFocused: true),
        ),
      );

      expect(find.text('Room dari PIN yang kamu masukkan'), findsOneWidget);
    });
  });

  group('Widget auth', () {
    testWidgets('PasswordField menyembunyikan lalu menampilkan teks', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          PasswordField(
            controller: TextEditingController(),
            label: 'Password',
          ),
        ),
      );

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, true);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(tester.widget<TextField>(find.byType(TextField)).obscureText, false);
    });

    testWidgets('AuthSubmitButton menampilkan label dan memanggil onPressed', (
      WidgetTester tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(
          AuthSubmitButton(
            label: 'Daftar',
            loading: false,
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.text('Daftar'), findsOneWidget);
      await tester.tap(find.text('Daftar'));
      expect(taps, 1);
    });

    testWidgets('AuthSubmitButton saat loading menampilkan spinner', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          AuthSubmitButton(
            label: 'Daftar',
            loading: true,
            onPressed: () {},
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('Widget testing kuis', () {
    testWidgets('QuizQuestionCard menampilkan teks pertanyaan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizQuestionCard(question: 'Ibu kota Indonesia?')),
      );

      expect(find.text('Ibu kota Indonesia?'), findsOneWidget);
    });

    testWidgets('QuizTestHeader menampilkan progres dan skor', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QuizTestHeader(
            title: 'Kuis Matematika',
            currentIndex: 1,
            totalQuestions: 5,
            maxScore: 100,
            totalScore: 40,
          ),
        ),
      );

      expect(find.text('Soal 2'), findsOneWidget);
      expect(find.text('Max 100 pts'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
    });
  });

  group('AppBottomSheet', () {
    testWidgets('menampilkan judul dan konten', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(
          const AppBottomSheet(
            title: 'Create Room',
            children: [Text('isi sheet')],
          ),
        ),
      );

      expect(find.text('Create Room'), findsOneWidget);
      expect(find.text('isi sheet'), findsOneWidget);
    });
  });

  group('Widget enter pin', () {
    testWidgets('PinInputField menerima hanya 6 digit angka', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      await tester.pumpWidget(
        _wrap(PinInputField(controller: controller)),
      );

      await tester.enterText(find.byType(TextField), '12ab34567');
      expect(controller.text, '123456');
    });

    testWidgets('EnterPinIntroCard menampilkan ajakan gabung', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const EnterPinIntroCard()));

      expect(find.text('Gabung ke Room'), findsOneWidget);
    });
  });

  group('RoomListTile', () {
    testWidgets('menampilkan nomor, kode, dan memanggil onTap', (
      WidgetTester tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          RoomListTile(
            room: _room(),
            index: 1,
            quizTitle: 'Kuis Matematika',
            onTap: () => tapped++,
          ),
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.text('123456'), findsOneWidget);
      expect(find.text('Kuis Matematika'), findsOneWidget);

      await tester.tap(find.byType(RoomListTile));
      expect(tapped, 1);
    });
  });
}
