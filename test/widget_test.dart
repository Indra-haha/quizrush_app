import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('Login page menampilkan field username dan password', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuizApp());

    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Login'), findsOneWidget);
  });

  testWidgets('Login tanpa input menampilkan pesan error', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const QuizApp());

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Username dan password wajib diisi'), findsOneWidget);
  });
}
