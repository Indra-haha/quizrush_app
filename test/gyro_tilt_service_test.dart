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

