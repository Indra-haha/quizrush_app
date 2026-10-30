import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/pages/Profiles/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'fake-token',
      'auth_user': '{"username":"budi123","nama":"Budi Santoso","kelas":"SI-A"}',
    });
  });

  testWidgets('ProfilePage displays user info and avatar initials when url_img is empty',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfilePage(
          user: {
            'username': 'budi123',
            'nama': 'Budi Santoso',
            'kelas': 'SI-A',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Budi Santoso'), findsOneWidget);
    expect(find.text('@budi123'), findsOneWidget);
    expect(find.text('SI-A'), findsOneWidget);
    // Initials BS
    expect(find.text('BS'), findsOneWidget);
    // Camera icon badge
    expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
  });
}

