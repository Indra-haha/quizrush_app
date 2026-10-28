import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/pages/Profiles/sensor_settings.dart';
import 'package:quizrush/services/profile_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'profile_accelerometer_enabled': true,
      'profile_gyroscope_enabled': true,
    });
  });

  testWidgets('SensorSettingsPage renders gyroscope and accelerometer cards',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: SensorSettingsPage(title: 'Pengaturan Sensor'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pengaturan Sensor'), findsOneWidget);
    expect(find.text('Aktifkan\nAccelerometer'), findsOneWidget);
    expect(find.text('Aktifkan\nGyroscope'), findsOneWidget);

    // Verify 4 tilt options
    expect(find.text('Ke Kiri'), findsOneWidget);
    expect(find.text('Ke Kanan'), findsOneWidget);
    expect(find.text('Tilt Depan / Atas'), findsOneWidget);
    expect(find.text('Tilt Belakang / Bawah'), findsOneWidget);
  });

  testWidgets('Selecting a tilt option updates selection and shows notification',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SensorSettingsPage(title: 'Pengaturan Sensor'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap on 'Tilt Depan / Atas' (index 2)
    final depanFinder = find.text('Tilt Depan / Atas');
    expect(depanFinder, findsOneWidget);
    await tester.ensureVisible(depanFinder);
    await tester.tap(depanFinder);
    await tester.pump();

    // Verify SnackBar notification appears
    expect(find.textContaining('Tilt Depan / Atas'), findsWidgets);
  });

  test('ProfileSettingsService gyro baseline save, load, and clear', () async {
    final service = ProfileSettingsService.instance;
    expect(await service.isGyroCalibrated(), isFalse);
    expect(await service.getGyroBaseline(), isNull);

    await service.setGyroBaseline(x: 0.12, y: 5.43, z: 8.11);
    expect(await service.isGyroCalibrated(), isTrue);

    final baseline = await service.getGyroBaseline();
    expect(baseline, isNotNull);
    expect(baseline!['x'], closeTo(0.12, 0.001));
    expect(baseline['y'], closeTo(5.43, 0.001));
    expect(baseline['z'], closeTo(8.11, 0.001));

    await service.clearGyroBaseline();
    expect(await service.isGyroCalibrated(), isFalse);
    expect(await service.getGyroBaseline(), isNull);
  });
}
