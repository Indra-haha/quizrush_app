import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/helpers/shake_service.dart';
import 'package:sensors_plus/sensors_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShakeService', () {
    test('magnitudeOf calculates correct 3D magnitude', () {
      expect(ShakeService.magnitudeOf(3, 4, 0), closeTo(5.0, 0.001));
      expect(ShakeService.magnitudeOf(0, 0, 0), 0.0);
    });

    test('readings transforms raw events into ShakeReading', () async {
      final controller = StreamController<UserAccelerometerEvent>();
      final service = ShakeService(source: () => controller.stream);

      final readingsFuture = service.readings(threshold: 10.0).take(2).toList();

      final now = DateTime.now();
      controller.add(UserAccelerometerEvent(3.0, 4.0, 0.0, now));
      controller.add(UserAccelerometerEvent(0.0, 10.0, 0.0, now));

      final readings = await readingsFuture;
      expect(readings.length, 2);
      expect(readings[0].magnitude, closeTo(5.0, 0.001));
      expect(readings[0].isShaking, isFalse);

      expect(readings[1].magnitude, closeTo(10.0, 0.001));
      expect(readings[1].isShaking, isTrue);

      await controller.close();
    });

    test('shakeEvents respects cooldown', () async {
      final controller = StreamController<UserAccelerometerEvent>();
      final service = ShakeService(source: () => controller.stream);

      final eventsFuture = service
          .shakeEvents(
            threshold: 10.0,
            cooldown: const Duration(milliseconds: 500),
          )
          .take(2)
          .toList();

      final t0 = DateTime(2026, 1, 1, 12, 0, 0);
      final t1 = t0.add(const Duration(milliseconds: 200)); // within cooldown
      final t2 = t0.add(const Duration(milliseconds: 600)); // after cooldown

      controller.add(UserAccelerometerEvent(0, 15, 0, t0)); // triggers #1
      controller.add(UserAccelerometerEvent(0, 20, 0, t1)); // ignored (cooldown)
      controller.add(UserAccelerometerEvent(0, 18, 0, t2)); // triggers #2

      final events = await eventsFuture;
      expect(events.length, 2);
      expect(events[0].timestamp, t0);
      expect(events[1].timestamp, t2);

      await controller.close();
    });
  });
}

