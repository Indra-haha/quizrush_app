import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/helpers/gyro_tilt_service.dart';
import 'package:quizrush/services/profile_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TiltDirection', () {
    test('maps index to correct direction', () {
      expect(TiltDirection.fromIndex(0), TiltDirection.left);
      expect(TiltDirection.fromIndex(1), TiltDirection.right);
      expect(TiltDirection.fromIndex(2), TiltDirection.forward);
      expect(TiltDirection.fromIndex(3), TiltDirection.backward);
      expect(TiltDirection.fromIndex(4), isNull);
      expect(TiltDirection.fromIndex(-1), isNull);
    });

    test('has expected names and indices', () {
      expect(TiltDirection.left.name, 'Ke Kiri');
      expect(TiltDirection.left.index, 0);

      expect(TiltDirection.right.name, 'Ke Kanan');
      expect(TiltDirection.right.index, 1);

      expect(TiltDirection.forward.name, 'Tilt Depan / Atas');
      expect(TiltDirection.forward.index, 2);

      expect(TiltDirection.backward.name, 'Tilt Belakang / Bawah');
      expect(TiltDirection.backward.index, 3);
    });
  });

  group('Angle Calculations', () {
    test('calculatePitch computes forward/backward degrees accurately', () {
      // Phone vertical: y = 9.8, x = 0, z = 0 -> 90 degrees
      expect(GyroTiltService.calculatePitch(0, 9.8, 0), closeTo(90.0, 0.1));

      // Phone flat on table: y = 0, x = 0, z = 9.8 -> 0 degrees
      expect(GyroTiltService.calculatePitch(0, 0, 9.8), closeTo(0.0, 0.1));

      // Phone reading position at 45 degrees
      final g = 9.8;
      final y45 = g * math.sin(45 * math.pi / 180);
      final z45 = g * math.cos(45 * math.pi / 180);
      expect(GyroTiltService.calculatePitch(0, y45, z45), closeTo(45.0, 0.1));

      // Tilt forward 15 degrees: from 45 down to 30 degrees
      final y30 = g * math.sin(30 * math.pi / 180);
      final z30 = g * math.cos(30 * math.pi / 180);
      final pitch30 = GyroTiltService.calculatePitch(0, y30, z30);
      final pitch45 = GyroTiltService.calculatePitch(0, y45, z45);
      expect(pitch30 - pitch45, closeTo(-15.0, 0.1));
    });

    test('calculateRoll computes left/right degrees accurately', () {
      final g = 9.8;

      // Phone flat without roll
      expect(GyroTiltService.calculateRoll(0, 0, g), closeTo(0.0, 0.1));

      // Tilt left 15 degrees (x becomes positive)
      final xLeft15 = g * math.sin(15 * math.pi / 180);
      final zLeft15 = g * math.cos(15 * math.pi / 180);
      expect(GyroTiltService.calculateRoll(xLeft15, 0, zLeft15), closeTo(15.0, 0.1));

      // Tilt right 15 degrees (x becomes negative)
      final xRight15 = -g * math.sin(15 * math.pi / 180);
      final zRight15 = g * math.cos(15 * math.pi / 180);
      expect(GyroTiltService.calculateRoll(xRight15, 0, zRight15), closeTo(-15.0, 0.1));
    });
  });

  group('GyroTiltService', () {
    test('init loads saved baseline from ProfileSettingsService', () async {
      await ProfileSettingsService.instance.setGyroBaseline(
        x: 1.0,
        y: 2.0,
        z: 3.0,
      );

      final service = GyroTiltService();
      expect(service.hasBaseline, isFalse);

      await service.init();
      expect(service.hasBaseline, isTrue);

      service.recalibrate();
      expect(service.hasBaseline, isFalse);

      service.resetNeutral();
      service.dispose();
      expect(service.isListening, isFalse);
    });
  });
}
