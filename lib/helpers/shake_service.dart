import 'dart:async';
import 'dart:math' as math;

import 'package:sensors_plus/sensors_plus.dart';

class ShakeReading {
  const ShakeReading({
    required this.magnitude,
    required this.isShaking,
    required this.timestamp,
  });

  final double magnitude;
  final bool isShaking;
  final DateTime timestamp;
}

class ShakeService {
  ShakeService({Stream<UserAccelerometerEvent> Function()? source})
    : _source = source ?? _deviceEvents;

  static final ShakeService instance = ShakeService();

  static const double defaultThreshold = 12.0;
  static const Duration defaultSamplingPeriod = SensorInterval.gameInterval;

  final Stream<UserAccelerometerEvent> Function() _source;

  static Stream<UserAccelerometerEvent> _deviceEvents() =>
      userAccelerometerEventStream(samplingPeriod: defaultSamplingPeriod);

  static double magnitudeOf(double x, double y, double z) =>
      math.sqrt(x * x + y * y + z * z);

  Stream<ShakeReading> readings({double threshold = defaultThreshold}) {
    return _source().map((event) {
      final magnitude = magnitudeOf(event.x, event.y, event.z);
      return ShakeReading(
        magnitude: magnitude,
        isShaking: magnitude >= threshold,
        timestamp: event.timestamp,
      );
    });
  }

  Stream<ShakeReading> shakeEvents({
    double threshold = defaultThreshold,
    Duration cooldown = const Duration(milliseconds: 600),
  }) async* {
    var lastShake = DateTime.fromMillisecondsSinceEpoch(0);
    await for (final reading in readings(threshold: threshold)) {
      if (!reading.isShaking) continue;
      if (reading.timestamp.difference(lastShake) < cooldown) continue;
      lastShake = reading.timestamp;
      yield reading;
    }
  }

  Future<bool> isAvailable({Duration timeout = const Duration(seconds: 1)}) async {
    return await detectOnce(timeout: timeout) != null;
  }

  Future<ShakeReading?> detectOnce({
    Duration timeout = const Duration(seconds: 2),
    double threshold = defaultThreshold,
  }) {
    final completer = Completer<ShakeReading?>();
    StreamSubscription<UserAccelerometerEvent>? subscription;
    var strongest = 0.0;
    var active = false;
    DateTime? at;

    void finish(ShakeReading? reading) {
      if (completer.isCompleted) return;
      completer.complete(reading);
    }

    final timer = Timer(timeout, () {
      subscription?.cancel();
      finish(
        active
            ? ShakeReading(
                magnitude: strongest,
                isShaking: strongest >= threshold,
                timestamp: at ?? DateTime.now(),
              )
            : null,
      );
    });

    subscription = _source().listen(
      (event) {
        final magnitude = magnitudeOf(event.x, event.y, event.z);
        active = true;
        if (magnitude >= strongest) {
          strongest = magnitude;
          at = event.timestamp;
        }
        if (magnitude >= threshold) {
          timer.cancel();
          subscription?.cancel();
          finish(
            ShakeReading(
              magnitude: magnitude,
              isShaking: true,
              timestamp: event.timestamp,
            ),
          );
        }
      },
      onError: (_) {
        timer.cancel();
        finish(null);
      },
      cancelOnError: true,
    );

    return completer.future;
  }
}
