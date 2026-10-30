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

import 'dart:async';
import 'dart:math' as math;

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
    this.angleDegrees = 0.0,
  });

  final TiltDirection direction;
  final int index;
  final String directionName;
  final IconData icon;
  final double angleDegrees;
}

/// Informasi sudut kemiringan real-time untuk visualisasi & kalibrasi.
class TiltAngleInfo {
  const TiltAngleInfo({
    required this.pitch,
    required this.roll,
    required this.deltaPitch,
    required this.deltaRoll,
    required this.dominantAngle,
    required this.direction,
    required this.isNeutral,
    required this.isCalibrating,
    required this.hasBaseline,
    required this.triggerAngle,
  });

  final double pitch;
  final double roll;
  final double deltaPitch;
  final double deltaRoll;
  final double dominantAngle;
  final TiltDirection? direction;
  final bool isNeutral;
  final bool isCalibrating;
  final bool hasBaseline;
  final double triggerAngle;
}

/// Service pemersatu untuk pendeteksian kemiringan (tilt) 4 arah
/// menggunakan perpaduan sinyal Accelerometer dan Gyroscope, lengkap
/// dengan kalibrasi baseline posisi awal (0°) dan threshold sudut (min. 15 derajat).
class GyroTiltService {
  GyroTiltService({ProfileSettingsService? settings})
      : _settings = settings ?? ProfileSettingsService.instance;

  static final GyroTiltService instance = GyroTiltService();

  static const double defaultTriggerAngle = 15.0;
  static const double defaultNeutralAngle = 8.0;
  static const int defaultCalibrationSamples = 8;
  static const double _lowPassAlpha = 0.35;

  final ProfileSettingsService _settings;

  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;

  bool _enabled = false;
  bool _hasBaseline = false;
  bool _isCalibrating = false;
  int _calibrationSamples = 0;
  double _sumAccX = 0.0;
  double _sumAccY = 0.0;
  double _sumAccZ = 0.0;
  double _baseAccX = 0.0;
  double _baseAccY = 0.0;
  double _baseAccZ = 0.0;
  double _basePitch = 0.0;
  double _baseRoll = 0.0;

  double _smoothAccX = 0.0;
  double _smoothAccY = 0.0;
  double _smoothAccZ = 0.0;

  double _currentPitch = 0.0;
  double _currentRoll = 0.0;

  bool _isNeutral = true;
  int? _lastChosenIndex;
  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);

  void Function(TiltAngleInfo info)? _onAngleUpdate;
  VoidCallback? _onCalibrated;
  void Function(TiltEvent event)? _onTilt;
  Duration _cooldown = const Duration(milliseconds: 800);
  double _triggerAngle = defaultTriggerAngle;
  double _neutralAngle = defaultNeutralAngle;

  bool get hasBaseline => _hasBaseline;
  bool get isCalibrating => _isCalibrating;
  bool get isListening => _accelSub != null || _gyroSub != null;
  double get basePitch => _basePitch;
  double get baseRoll => _baseRoll;
  double get currentPitch => _currentPitch;
  double get currentRoll => _currentRoll;
  double get deltaPitch => _hasBaseline ? (_currentPitch - _basePitch) : 0.0;
  double get deltaRoll => _hasBaseline ? (_currentRoll - _baseRoll) : 0.0;

  /// Menghitung sudut Pitch (kemiringan depan/belakang) dalam derajat (-90° s.d. +90°).
  static double calculatePitch(double x, double y, double z) {
    final denom = math.sqrt(x * x + z * z);
    return math.atan2(y, denom) * (180.0 / math.pi);
  }

  /// Menghitung sudut Roll (kemiringan kiri/kanan) dalam derajat (-90° s.d. +90°).
  static double calculateRoll(double x, double y, double z) {
    final denom = math.sqrt(y * y + z * z);
    return math.atan2(x, denom) * (180.0 / math.pi);
  }

  /// Memuat baseline tersimpan dari preferences.
  Future<void> init() async {
    final baseline = await _settings.getGyroBaseline();
    if (baseline != null) {
      _baseAccX = baseline['x']!;
      _baseAccY = baseline['y']!;
      _baseAccZ = baseline['z']!;
      _basePitch = calculatePitch(_baseAccX, _baseAccY, _baseAccZ);
      _baseRoll = calculateRoll(_baseAccX, _baseAccY, _baseAccZ);
      _smoothAccX = _baseAccX;
      _smoothAccY = _baseAccY;
      _smoothAccZ = _baseAccZ;
      _currentPitch = _basePitch;
      _currentRoll = _baseRoll;
      _hasBaseline = true;
    }
  }

  /// Mulai mendengarkan sensor kemiringan dengan batas sudut (default 15 derajat).
  void start({
    required void Function(TiltEvent event) onTilt,
    VoidCallback? onCalibrated,
    void Function(TiltAngleInfo info)? onAngleUpdate,
    Duration cooldown = const Duration(milliseconds: 800),
    double triggerAngle = defaultTriggerAngle,
    double neutralAngle = defaultNeutralAngle,
  }) {
    stop();
    _enabled = true;
    _onTilt = onTilt;
    _onCalibrated = onCalibrated;
    _onAngleUpdate = onAngleUpdate;
    _cooldown = cooldown;
    _triggerAngle = triggerAngle;
    _neutralAngle = neutralAngle;
    _isNeutral = true;
    _lastChosenIndex = null;

    if (!_hasBaseline) {
      recalibrate();
    }

    try {
      _accelSub = accelerometerEventStream(
        samplingPeriod: SensorInterval.uiInterval,
      ).listen(
        (event) {
          if (!_enabled) return;
          _handleAccelerometerEvent(event);
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
        },
        onError: (_) => _cancelGyro(),
        cancelOnError: true,
      );
    } catch (_) {
      _cancelGyro();
    }
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    if (!_hasBaseline || _isCalibrating) {
      _sumAccX += event.x;
      _sumAccY += event.y;
      _sumAccZ += event.z;
      _calibrationSamples++;

      if (_calibrationSamples >= defaultCalibrationSamples) {
        _baseAccX = _sumAccX / _calibrationSamples;
        _baseAccY = _sumAccY / _calibrationSamples;
        _baseAccZ = _sumAccZ / _calibrationSamples;
        _basePitch = calculatePitch(_baseAccX, _baseAccY, _baseAccZ);
        _baseRoll = calculateRoll(_baseAccX, _baseAccY, _baseAccZ);
        _smoothAccX = _baseAccX;
        _smoothAccY = _baseAccY;
        _smoothAccZ = _baseAccZ;
        _currentPitch = _basePitch;
        _currentRoll = _baseRoll;
        _hasBaseline = true;
        _isCalibrating = false;
        _isNeutral = true;
        _lastChosenIndex = null;

        unawaited(
          _settings.setGyroBaseline(
            x: _baseAccX,
            y: _baseAccY,
            z: _baseAccZ,
          ),
        );
        _onCalibrated?.call();
      }

      _emitAngleUpdate();
      return;
    }

    // Low-pass exponential smoothing untuk meredam jitter sentuhan & getaran
    _smoothAccX = _smoothAccX * (1.0 - _lowPassAlpha) + event.x * _lowPassAlpha;
    _smoothAccY = _smoothAccY * (1.0 - _lowPassAlpha) + event.y * _lowPassAlpha;
    _smoothAccZ = _smoothAccZ * (1.0 - _lowPassAlpha) + event.z * _lowPassAlpha;

    _currentPitch = calculatePitch(_smoothAccX, _smoothAccY, _smoothAccZ);
    _currentRoll = calculateRoll(_smoothAccX, _smoothAccY, _smoothAccZ);

    _evaluateMotion();
    _emitAngleUpdate();
  }

  void _evaluateMotion() {
    if (!_enabled || !_hasBaseline || _isCalibrating) return;

    final dPitch = _currentPitch - _basePitch;
    final dRoll = _currentRoll - _baseRoll;
    final absPitch = dPitch.abs();
    final absRoll = dRoll.abs();

    // Jika kemiringan kembali ke zona netral (< neutralAngle derajat)
    if (absPitch < _neutralAngle && absRoll < _neutralAngle) {
      _isNeutral = true;
      return;
    }

    // Hanya merespons jika kemiringan sudut telah mencapai triggerAngle (min. 15°)
    if (absPitch >= _triggerAngle || absRoll >= _triggerAngle) {
      TiltDirection? direction;
      double dominantAngle = 0.0;

      if (absPitch >= absRoll) {
        dominantAngle = absPitch;
        // Pitch berkurang saat bagian atas ponsel dimiringkan ke depan (menjauhi user)
        if (dPitch <= -_triggerAngle) {
          direction = TiltDirection.forward; // Opsi index 2: Tilt Depan / Atas
        } else if (dPitch >= _triggerAngle) {
          direction = TiltDirection.backward; // Opsi index 3: Tilt Belakang / Bawah
        }
      } else {
        dominantAngle = absRoll;
        // Roll bertambah positif saat dimiringkan ke kiri (sisi kiri turun)
        if (dRoll >= _triggerAngle) {
          direction = TiltDirection.left; // Opsi index 0: Ke Kiri
        } else if (dRoll <= -_triggerAngle) {
          direction = TiltDirection.right; // Opsi index 1: Ke Kanan
        }
      }

      if (direction != null) {
        final now = DateTime.now();
        final isDifferent = direction.index != _lastChosenIndex;
        final cooldownPassed = now.difference(_lastTriggerTime) > _cooldown;

        if (_isNeutral || isDifferent || cooldownPassed) {
          _isNeutral = false;
          _lastTriggerTime = now;
          _lastChosenIndex = direction.index;

          _onTilt?.call(
            TiltEvent(
              direction: direction,
              index: direction.index,
              directionName: direction.name,
              icon: direction.icon,
              angleDegrees: dominantAngle,
            ),
          );
        }
      }
    }
  }

  void _emitAngleUpdate() {
    if (_onAngleUpdate == null) return;

    final dPitch = _hasBaseline ? (_currentPitch - _basePitch) : 0.0;
    final dRoll = _hasBaseline ? (_currentRoll - _baseRoll) : 0.0;
    final absPitch = dPitch.abs();
    final absRoll = dRoll.abs();

    TiltDirection? currentDir;
    double dominantAngle = 0.0;

    if (_hasBaseline && !_isCalibrating) {
      if (absPitch >= absRoll) {
        dominantAngle = absPitch;
        if (dPitch <= -_triggerAngle) {
          currentDir = TiltDirection.forward;
        } else if (dPitch >= _triggerAngle) {
          currentDir = TiltDirection.backward;
        }
      } else {
        dominantAngle = absRoll;
        if (dRoll >= _triggerAngle) {
          currentDir = TiltDirection.left;
        } else if (dRoll <= -_triggerAngle) {
          currentDir = TiltDirection.right;
        }
      }
    }

    final info = TiltAngleInfo(
      pitch: _currentPitch,
      roll: _currentRoll,
      deltaPitch: dPitch,
      deltaRoll: dRoll,
      dominantAngle: dominantAngle,
      direction: currentDir,
      isNeutral: _isNeutral || (absPitch < _neutralAngle && absRoll < _neutralAngle),
      isCalibrating: _isCalibrating,
      hasBaseline: _hasBaseline,
      triggerAngle: _triggerAngle,
    );

    _onAngleUpdate!(info);
  }

  /// Mereset kondisi netral saat berpindah soal atau state baru.
  void resetNeutral() {
    _isNeutral = true;
    _lastChosenIndex = null;
  }

  /// Kalibrasi ulang posisi baseline (merekam posisi saat ini sebagai 0 derajat).
  void recalibrate({int sampleCount = defaultCalibrationSamples}) {
    _hasBaseline = false;
    _isCalibrating = true;
    _calibrationSamples = 0;
    _sumAccX = 0.0;
    _sumAccY = 0.0;
    _sumAccZ = 0.0;
    _isNeutral = true;
    _lastChosenIndex = null;
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
