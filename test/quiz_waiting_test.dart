import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/widgets/quiz_waiting.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  group('QuizWaitingHero', () {
    testWidgets('menampilkan judul kuis, GAME PIN, dan kode terformat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QuizWaitingHero(
            title: 'Dasar Dasar Pemrograman',
            pin: '882194',
          ),
        ),
      );

      expect(find.text('Dasar Dasar Pemrograman'), findsOneWidget);
      expect(find.text('GAME PIN'), findsOneWidget);
      expect(find.text('882 194'), findsOneWidget);
    });

    testWidgets('chip meta menampilkan jumlah soal dan total poin', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const QuizWaitingHero(
            title: 'Kuis',
            pin: '123456',
            stats: [
              QuizWaitingHeroStat(
                value: '30',
                icon: Icons.list_alt,
                background: Colors.green,
                foreground: Colors.black,
              ),
              QuizWaitingHeroStat(
                value: '3.434',
                icon: Icons.star_rounded,
                background: Colors.orange,
                foreground: Colors.black,
              ),
            ],
          ),
        ),
      );

      expect(find.text('30'), findsOneWidget);
      expect(find.text('3.434'), findsOneWidget);
    });

    testWidgets('ketuk kartu PIN memanggil onCopyPin', (
      WidgetTester tester,
    ) async {
      var copies = 0;
      await tester.pumpWidget(
        _wrap(
          QuizWaitingHero(
            title: 'Kuis',
            pin: '123456',
            onCopyPin: () => copies++,
          ),
        ),
      );

      await tester.tap(find.text('123 456'));
      expect(copies, 1);
    });

    testWidgets('tombol kembali hanya tampil bila onBack diberikan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizWaitingHero(title: 'Kuis', pin: '123456')),
      );
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      var backs = 0;
      await tester.pumpWidget(
        _wrap(
          QuizWaitingHero(title: 'Kuis', pin: '123456', onBack: () => backs++),
        ),
      );
      await tester.tap(find.byIcon(Icons.arrow_back));
      expect(backs, 1);
    });

    testWidgets('tidak meluber di layar kecil', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          const QuizWaitingHero(
            title: 'Dasar Dasar Pemrograman Dart',
            pin: '882194',
            stats: [
              QuizWaitingHeroStat(
                value: '30',
                icon: Icons.list_alt,
                background: Colors.green,
                foreground: Colors.black,
              ),
              QuizWaitingHeroStat(
                value: '3.434',
                icon: Icons.star_rounded,
                background: Colors.orange,
                foreground: Colors.black,
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('tidak meluber pada text scale besar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: const QuizWaitingHero(
              title: 'Dasar Dasar Pemrograman',
              pin: '882194',
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });
  });

  group('QuizWaitingStats', () {
    testWidgets('menampilkan jumlah peserta, status, dan koneksi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizWaitingStats(participantCount: 3)),
      );

      expect(find.text('3 Peserta'), findsOneWidget);
      expect(find.text('Menunggu host'), findsOneWidget);
      expect(find.text('Tersambung'), findsOneWidget);
    });

    testWidgets('menampilkan status koneksi saat terputus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizWaitingStats(participantCount: 1, connected: false)),
      );

      expect(find.text('Menyambung'), findsOneWidget);
    });

    testWidgets('chip koneksi memicu sambung ulang saat terputus', (
      WidgetTester tester,
    ) async {
      var reconnects = 0;
      await tester.pumpWidget(
        _wrap(
          QuizWaitingStats(
            participantCount: 1,
            connected: false,
            onReconnect: () => reconnects++,
          ),
        ),
      );

      await tester.tap(find.text('Menyambung'));
      expect(reconnects, 1);
    });

    testWidgets('chip koneksi tidak bisa diketuk saat tersambung', (
      WidgetTester tester,
    ) async {
      var reconnects = 0;
      await tester.pumpWidget(
        _wrap(
          QuizWaitingStats(
            participantCount: 1,
            onReconnect: () => reconnects++,
          ),
        ),
      );

      await tester.tap(find.text('Tersambung'));
      expect(reconnects, 0);
    });
  });

  group('QuizWaitingParticipant', () {
    testWidgets('menampilkan inisial dan nama peserta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const QuizWaitingParticipant(name: 'Siti Smart')),
      );

      expect(find.text('S'), findsOneWidget);
      expect(find.text('Siti Smart'), findsOneWidget);
      expect(find.text('Host'), findsNothing);
    });

    testWidgets('menandai peserta sebagai host', (WidgetTester tester) async {
      await tester.pumpWidget(
        _wrap(const QuizWaitingParticipant(name: 'Budi', isHost: true)),
      );

      expect(find.text('Host'), findsOneWidget);
    });
  });

  group('QuizWaitingSlot', () {
    testWidgets('menampilkan label menunggu', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(const QuizWaitingSlot()));

      expect(find.text('Menunggu...'), findsOneWidget);
    });
  });
}
