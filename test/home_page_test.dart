import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/pages/Home/home_page.dart';
import 'package:quizrush/services/cache/quiz_cache_service.dart';
import 'package:quizrush/services/points_store.dart';
import 'package:quizrush/widgets/home_stat_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await QuizCacheService.instance.clear();
  });

  testWidgets('HomePage menampilkan kartu statistik dinamis dari data cache dan points', (
    WidgetTester tester,
  ) async {
    // Siapkan points di PointsStore
    PointsStore.instance.set(3500);

    // Siapkan data quiz dengan room
    final quiz1 = Quizes(
      id: 'q1',
      userId: 'u1',
      title: 'Kuis Geografi',
      description: 'Soal geografi nusantara',
      questions: const [],
      createdAt: DateTime.now().toIso8601String(),
      rooms: [
        RoomSummary(
          id: 'r1',
          kode: '123456',
          status: 'open',
          createdAt: DateTime.now().toIso8601String(),
        ),
        RoomSummary(
          id: 'r2',
          kode: '654321',
          status: 'ended',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ],
    );

    final quiz2 = Quizes(
      id: 'q2',
      userId: 'u1',
      title: 'Kuis Sejarah',
      description: 'Soal sejarah',
      questions: const [],
      createdAt: DateTime.now().toIso8601String(),
      rooms: [
        RoomSummary(
          id: 'r3',
          kode: '112233',
          status: 'open',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ],
    );

    final myQuizzes = MyQuizzes(open: [quiz1, quiz2]);

    // Simpan ke cache kuis
    await QuizCacheService.instance.saveMyQuizzes(myQuizzes);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );
    await tester.pumpAndSettle();

    // Verifikasi HomeStatCard
    expect(find.byType(HomeStatCard), findsNWidgets(4));

    // Kartu 1: Total Main (3 rooms total)
    expect(find.text('Total Main'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);

    // Kartu 2: Saldo Pts (3.500)
    expect(find.text('Saldo Pts'), findsOneWidget);
    expect(find.text('3.500'), findsOneWidget);

    // Kartu 3: Host Aktif (2 room berstatus 'open')
    expect(find.text('Host Aktif'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // Kartu 4: Terakhir Update
    expect(find.text('Terakhir Update'), findsOneWidget);
  });
}
