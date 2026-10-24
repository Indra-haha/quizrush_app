import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'session_service.dart';

class CompassCalibration {
  const CompassCalibration({
    required this.baselineX,
    required this.baselineY,
    required this.baselineZ,
    required this.threshold,
    required this.calibratedAt,
    required this.enabled,
  });

  final double baselineX;
  final double baselineY;
  final double baselineZ;
  final double threshold;
  final DateTime calibratedAt;
  final bool enabled;

  Map<String, dynamic> toJson() => {
        'baselineX': baselineX,
        'baselineY': baselineY,
        'baselineZ': baselineZ,
        'threshold': threshold,
        'calibratedAt': calibratedAt.toIso8601String(),
        'enabled': enabled,
      };

  factory CompassCalibration.fromJson(Map<String, dynamic> json) {
    return CompassCalibration(
      baselineX: (json['baselineX'] as num?)?.toDouble() ?? 0.0,
      baselineY: (json['baselineY'] as num?)?.toDouble() ?? 0.0,
      baselineZ: (json['baselineZ'] as num?)?.toDouble() ?? 0.0,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 1.5,
      calibratedAt: DateTime.tryParse(json['calibratedAt'] as String? ?? '') ??
          DateTime.now(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  CompassCalibration copyWith({
    double? baselineX,
    double? baselineY,
    double? baselineZ,
    double? threshold,
    DateTime? calibratedAt,
    bool? enabled,
  }) {
    return CompassCalibration(
      baselineX: baselineX ?? this.baselineX,
      baselineY: baselineY ?? this.baselineY,
      baselineZ: baselineZ ?? this.baselineZ,
      threshold: threshold ?? this.threshold,
      calibratedAt: calibratedAt ?? this.calibratedAt,
      enabled: enabled ?? this.enabled,
    );
  }
}

enum CompassDirection { north, east, south, west, center, unknown }

class CompassReading {
  const CompassReading({
    required this.direction,
    required this.deltaX,
    required this.deltaY,
    required this.magnitude,
    required this.rawX,
    required this.rawY,
    required this.rawZ,
  });

  final CompassDirection direction;
  final double deltaX;
  final double deltaY;
  final double magnitude;
  final double rawX;
  final double rawY;
  final double rawZ;
}

class CompassCalibrationService {
  CompassCalibrationService._();
  static final CompassCalibrationService instance = CompassCalibrationService._();

  static const double defaultThreshold = 1.5;
  static const _prefix = 'compass_calibration_';

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  CompassCalibration? _calibration;
  final _readingController = StreamController<CompassReading>.broadcast();

  Stream<CompassReading> get readings => _readingController.stream;

  Future<String> _scope() async {
    final user = await SessionService.instance.getUser();
    final username = (user?['username'] as String?)?.trim() ?? '';
    return username.isEmpty ? 'guest' : username;
  }

  String _key(String scope) => _prefix + scope;

  Future<CompassCalibration?> load() async {
    try {
      final scope = await _scope();
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(scope));
      if (raw == null) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      _calibration = CompassCalibration.fromJson(map);
      return _calibration;
    } catch (e) {
      debugPrint('Compass calibration load error: $e');
      return null;
    }
  }

  Future<CompassCalibration> calibrate({
    Duration sampleDuration = const Duration(milliseconds: 800),
    int sampleCount = 20,
  }) async {
    final samplesX = <double>[];
    final samplesY = <double>[];
    final samplesZ = <double>[];

    final completer = Completer<CompassCalibration>();
    StreamSubscription<GyroscopeEvent>? sub;

    sub = gyroscopeEventStream(samplingPeriod: SensorInterval.gameInterval)
        .listen((event) {
      samplesX.add(event.x);
      samplesY.add(event.y);
      samplesZ.add(event.z);
      if (samplesX.length >= sampleCount) {
        sub?.cancel();
      }
    });

    Future.delayed(sampleDuration, () async {
      await sub?.cancel();
      if (samplesX.isEmpty) {
        final cal = CompassCalibration(
          baselineX: 0,
          baselineY: 0,
          baselineZ: 0,
          threshold: defaultThreshold,
          calibratedAt: DateTime.now(),
          enabled: true,
        );
        await save(cal);
        completer.complete(cal);
        return;
      }

      double avg(List<double> list) {
        if (list.isEmpty) return 0;
        var sum = 0.0;
        for (final v in list) {
          sum += v;
        }
        return sum / list.length;
      }

      final cal = CompassCalibration(
        baselineX: avg(samplesX),
        baselineY: avg(samplesY),
        baselineZ: avg(samplesZ),
        threshold: defaultThreshold,
        calibratedAt: DateTime.now(),
        enabled: true,
      );
      await save(cal);
      _calibration = cal;
      completer.complete(cal);
    });

    return completer.future;
  }

  Future<void> save(CompassCalibration calibration) async {
    try {
      final scope = await _scope();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key(scope), jsonEncode(calibration.toJson()));
      _calibration = calibration;
    } catch (e) {
      debugPrint('Compass calibration save error: $e');
    }
  }

  Future<void> clear() async {
    try {
      final scope = await _scope();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(scope));
      _calibration = null;
      stop();
    } catch (e) {
      debugPrint('Compass calibration clear error: $e');
    }
  }

  void start() {
    stop();
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen(_handleEvent);
  }

  void stop() {
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  void _handleEvent(GyroscopeEvent event) {
    final cal = _calibration;
    if (cal == null || !cal.enabled) {
      _readingController.add(CompassReading(
        direction: CompassDirection.center,
        deltaX: 0,
        deltaY: 0,
        magnitude: 0,
        rawX: event.x,
        rawY: event.y,
        rawZ: event.z,
      ));
      return;
    }

    final dx = event.x - cal.baselineX;
    final dy = event.y - cal.baselineY;
    final magnitude = math.sqrt(dx * dx + dy * dy);

    CompassDirection dir = CompassDirection.center;
    if (magnitude > cal.threshold) {
      if (dy.abs() > dx.abs()) {
        if (dy < -cal.threshold) {
          dir = CompassDirection.north;
        } else if (dy > cal.threshold) {
          dir = CompassDirection.south;
        }
      } else {
        if (dx > cal.threshold) {
          dir = CompassDirection.east;
        } else if (dx < -cal.threshold) {
          dir = CompassDirection.west;
        }
      }
    }

    _readingController.add(CompassReading(
      direction: dir,
      deltaX: dx,
      deltaY: dy,
      magnitude: magnitude,
      rawX: event.x,
      rawY: event.y,
      rawZ: event.z,
    ));
  }

  void dispose() {
    stop();
    _readingController.close();
  }
}
