import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../services/profile_settings_service.dart';

/// Arah kemiringan (tilt) yang didukung oleh sistem kendali gestur.
enum TiltDirection {
  left(name: 'Ke Kiri', icon: Icons.arrow_back_rounded),
  right(name: 'Ke Kanan', icon: Icons.arrow_forward_rounded),
  forward(name: 'Tilt Depan / Atas', icon: Icons.arrow_upward_rounded),
  backward(name: 'Tilt Belakang / Bawah', icon: Icons.arrow_downward_rounded);

  const TiltDirection({
    required this.name,
    required this.icon,
  });

  final String name;
  final IconData icon;

  static TiltDirection? fromIndex(int idx) {
    if (idx >= 0 && idx < values.length) {
      return values[idx];
    }
    return null;
  }
}

/// Event hasil deteksi gerakan atau kemiringan perangkat.
class TiltEvent {
  const TiltEvent({
    required this.direction,
    required this.index,
    required this.directionName,
    required this.icon,
  });

  final TiltDirection direction;
  final int index;
  final String directionName;
  final IconData icon;
}

/// Service pemersatu untuk pendeteksian kemiringan (tilt) 4 arah
/// menggunakan perpaduan sinyal Accelerometer dan Gyroscope, lengkap
/// dengan auto-kalibrasi baseline 5-sampel dan debounce cooldown.
class GyroTiltService {
  GyroTiltService({ProfileSettingsService? settings})
      : _settings = settings ?? ProfileSettingsService.instance;

  static final GyroTiltService instance = GyroTiltService();

  final ProfileSettingsService _settings;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  bool _enabled = false;
  bool _hasBaseline = false;
  int _calibrationSamples = 0;
  double _sumAccX = 0.0;
  double _sumAccY = 0.0;
  double _sumAccZ = 0.0;
  double _baseAccX = 0.0;
  double _baseAccY = 0.0;
  double _baseAccZ = 0.0;

  double _currentAccX = 0.0;
  double _currentAccY = 0.0;
  double _currentGyroX = 0.0;
  double _currentGyroY = 0.0;

  bool _isNeutral = true;
  int? _lastChosenIndex;
  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);

  bool get hasBaseline => _hasBaseline;
  bool get isListening => _accelSub != null || _gyroSub != null;

  /// Memuat baseline tersimpan dari preferences.
  Future<void> init() async {
    final baseline = await _settings.getGyroBaseline();
    if (baseline != null) {
      _baseAccX = baseline['x']!;
      _baseAccY = baseline['y']!;
      _baseAccZ = baseline['z']!;
      _hasBaseline = true;
    }
  }

  /// Mulai mendengarkan sensor kemiringan.
  void start({
    required void Function(TiltEvent event) onTilt,
    VoidCallback? onCalibrated,
    Duration cooldown = const Duration(milliseconds: 1000),
  }) {
    stop();
    _enabled = true;

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (!_enabled) return;
          _currentAccX = event.x;
          _currentAccY = event.y;

          if (!_hasBaseline) {
            _sumAccX += event.x;
            _sumAccY += event.y;
            _sumAccZ += event.z;
            _calibrationSamples++;

            if (_calibrationSamples >= 5) {
              _baseAccX = _sumAccX / _calibrationSamples;
              _baseAccY = _sumAccY / _calibrationSamples;
              _baseAccZ = _sumAccZ / _calibrationSamples;
              _hasBaseline = true;
              unawaited(
                _settings.setGyroBaseline(
                  x: _baseAccX,
                  y: _baseAccY,
                  z: _baseAccZ,
                ),
              );
              onCalibrated?.call();
            }
            return;
          }

          _evaluateMotion(onTilt, cooldown);
        },
        onError: (_) => _cancelAccel(),
        cancelOnError: true,
      );
    } catch (_) {
      _cancelAccel();
    }

    try {
      _gyroSub = gyroscopeEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (!_enabled) return;
          _currentGyroX = event.x;
          _currentGyroY = event.y;

          if (_hasBaseline) {
            _evaluateMotion(onTilt, cooldown);
          }
        },
        onError: (_) => _cancelGyro(),
        cancelOnError: true,
      );
    } catch (_) {
      _cancelGyro();
    }
  }

  void _evaluateMotion(
    void Function(TiltEvent event) onTilt,
    Duration cooldown,
  ) {
    if (!_enabled || !_hasBaseline) return;

    final deltaAccX = _currentAccX - _baseAccX;
    final deltaAccY = _currentAccY - _baseAccY;
    final gyroPitch = _currentGyroX;
    final gyroRoll = _currentGyroY;

    final signalX = deltaAccX + (gyroRoll * 1.0);
    final signalY = deltaAccY + (gyroPitch * 1.0);

    const double triggerThreshold = 2.0;
    const double neutralThreshold = 0.8;

    final absX = signalX.abs();
    final absY = signalY.abs();

    if (absX < neutralThreshold && absY < neutralThreshold) {
      _isNeutral = true;
      return;
    }

    if (absX >= triggerThreshold || absY >= triggerThreshold) {
      TiltDirection? direction;

      if (absY > absX) {
        if (signalY < -triggerThreshold) {
          direction = TiltDirection.forward;
        } else if (signalY > triggerThreshold) {
          direction = TiltDirection.backward;
        }
      } else {
        if (signalX > triggerThreshold) {
          direction = TiltDirection.left;
        } else if (signalX < -triggerThreshold) {
          direction = TiltDirection.right;
        }
      }

      if (direction != null) {
        final now = DateTime.now();
        final isDifferent = direction.index != _lastChosenIndex;
        final cooldownPassed = now.difference(_lastTriggerTime) > cooldown;

        if (_isNeutral || isDifferent || cooldownPassed) {
          _isNeutral = false;
          _lastTriggerTime = now;
          _lastChosenIndex = direction.index;

          onTilt(
            TiltEvent(
              direction: direction,
              index: direction.index,
              directionName: direction.name,
              icon: direction.icon,
            ),
          );
        }
      }
    }
  }

  /// Mereset kondisi netral saat berpindah soal atau state baru.
  void resetNeutral() {
    _isNeutral = true;
    _lastChosenIndex = null;
  }

  /// Kalibrasi ulang posisi baseline.
  void recalibrate() {
    _hasBaseline = false;
    _calibrationSamples = 0;
    _sumAccX = 0.0;
    _sumAccY = 0.0;
    _sumAccZ = 0.0;
    _isNeutral = true;
  }

  /// Hentikan pembacaan sensor.
  void stop() {
    _enabled = false;
    _cancelAccel();
    _cancelGyro();
  }

  void _cancelAccel() {
    _accelSub?.cancel();
    _accelSub = null;
  }

  void _cancelGyro() {
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  void dispose() {
    stop();
  }
}
