import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/pages/friend_page.dart';
import 'package:quizrush/pages/profile_page.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('FriendPage', () {
    testWidgets('menampilkan judul dan empty state', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const FriendPage()));

      expect(find.text('Friend'), findsOneWidget);
      expect(find.text('Belum ada teman.'), findsOneWidget);
    });
  });

  group('ProfilePage', () {
    testWidgets('menampilkan data user dan tombol Logout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfilePage(
            user: {
              'nama': 'Budi Santoso',
              'username': 'budi',
              'kelas': 'XI IPA 1',
              'tanggal_lahir': '17/08/2006',
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('@budi'), findsOneWidget);
      expect(find.text('XI IPA 1'), findsOneWidget);
      expect(find.text('2006-08-17'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Logout'), findsOneWidget);
    });
  });
}
