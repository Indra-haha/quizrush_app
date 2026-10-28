import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../services/notification_service.dart';
import '../../services/profile_settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/points_indicator.dart';
import '../../widgets/quiz_question_editor.dart';

class SensorSettingsPage extends StatelessWidget {
  const SensorSettingsPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBarWithActions(
        title: title,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
        ),
        actions: const [PointsIndicator()],
      ),
      body: _buildbody(),
    );
  }

  Widget _buildbody() {
    return const Settings();
  }
}

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool _accelerometerEnabled = true;
  bool _gyroscopeEnabled = true;
  int _selectedTilt = 1;

  final List<TextEditingController> _tiltControllers = List.generate(
    4,
    (index) => TextEditingController(
      text: index == 0
          ? 'Ke Kiri'
          : index == 1
          ? 'Ke Kanan'
          : index == 2
          ? 'Tilt Depan / Atas'
          : 'Tilt Belakang / Bawah',
    ),
  );

  StreamSubscription<GyroscopeEvent>? _gyroSub;
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<UserAccelerometerEvent>? _shakeSub;

  // Baseline / posisi awal yang ditangkap saat toggle aktif
  bool _hasBaseline = false;
  int _calibrationSamples = 0;
  double _sumAccX = 0.0;
  double _sumAccY = 0.0;
  double _sumAccZ = 0.0;

  double _baseAccX = 0.0;
  double _baseAccY = 0.0;
  double _baseAccZ = 0.0;

  // Pembacaan sensor terkini
  double _currentAccX = 0.0;
  double _currentAccY = 0.0;
  double _currentAccZ = 0.0;

  double _currentGyroX = 0.0;
  double _currentGyroY = 0.0;
  double _currentGyroZ = 0.0;

  // State debounce & netral
  bool _isNeutral = true;
  DateTime _lastTriggerTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastShakeTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ProfileSettingsService.instance;
    final acc = await service.accelerometerEnabled();
    final gyro = await service.gyroscopeEnabled();
    final savedBaseline = await service.getGyroBaseline();
    if (!mounted) return;
    setState(() {
      _accelerometerEnabled = acc;
      _gyroscopeEnabled = gyro;
      if (savedBaseline != null) {
        _baseAccX = savedBaseline['x']!;
        _baseAccY = savedBaseline['y']!;
        _baseAccZ = savedBaseline['z']!;
        _hasBaseline = true;
      }
    });

    if (acc) {
      _startShakeDetection();
    }
    if (gyro) {
      _startGyroscopeDetection();
    }
  }

  Future<void> _toggleAccelerometer(bool value) async {
    setState(() => _accelerometerEnabled = value);
    await ProfileSettingsService.instance.setAccelerometerEnabled(value);
    if (value) {
      _startShakeDetection();
    } else {
      _shakeSub?.cancel();
      _shakeSub = null;
    }
  }

  Future<void> _toggleGyroscope(bool value) async {
    setState(() => _gyroscopeEnabled = value);
    await ProfileSettingsService.instance.setGyroscopeEnabled(value);
    if (value) {
      _startGyroscopeDetection(notifyOnReady: true);
    } else {
      _stopGyroscopeDetection();
    }
  }

  void _recalibrateInitialPosition() {
    if (!_gyroscopeEnabled) return;
    setState(() {
      _hasBaseline = false;
      _calibrationSamples = 0;
      _sumAccX = 0.0;
      _sumAccY = 0.0;
      _sumAccZ = 0.0;
      _isNeutral = true;
    });

    HapticFeedback.lightImpact();

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.crop_rotate_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mengkalibrasi posisi awal... Tahan posisi ponsel.',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _startGyroscopeDetection({bool notifyOnReady = false}) {
    _stopGyroscopeDetection();

    _hasBaseline = false;
    _calibrationSamples = 0;
    _sumAccX = 0.0;
    _sumAccY = 0.0;
    _sumAccZ = 0.0;
    _isNeutral = true;

    // Menangkap orientasi gravitasi & tilt statis awal
    _accelSub =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.uiInterval,
        ).listen((event) {
          if (!_gyroscopeEnabled || !mounted) return;

          _currentAccX = event.x;
          _currentAccY = event.y;
          _currentAccZ = event.z;

          // 5 sampel awal dijadikan posisi awal (baseline)
          if (!_hasBaseline) {
            _sumAccX += event.x;
            _sumAccY += event.y;
            _sumAccZ += event.z;
            _calibrationSamples++;

            if (_calibrationSamples >= 5) {
              _baseAccX = _sumAccX / _calibrationSamples;
              _baseAccY = _sumAccY / _calibrationSamples;
              _baseAccZ = _sumAccZ / _calibrationSamples;
              setState(() {
                _hasBaseline = true;
              });
              unawaited(
                ProfileSettingsService.instance.setGyroBaseline(
                  x: _baseAccX,
                  y: _baseAccY,
                  z: _baseAccZ,
                ),
              );

              if (notifyOnReady && mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Colors.white),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Posisi awal gyroscope disimpan! Gerakkan ke depan/belakang atau miringkan ke kiri/kanan.',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.primary,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }
            }
            return;
          }

          _evaluateMotionAndTilt();
        });

    // Menangkap pergerakan dinamis & goyangan melalui gyroscope
    _gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((event) {
          if (!_gyroscopeEnabled || !mounted) return;

          _currentGyroX = event.x;
          _currentGyroY = event.y;
          _currentGyroZ = event.z;

          if (_hasBaseline) {
            _evaluateMotionAndTilt();
          }
        });
  }

  void _stopGyroscopeDetection() {
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
    _hasBaseline = false;
  }

  void _startShakeDetection() {
    _shakeSub?.cancel();
    _shakeSub = userAccelerometerEventStream().listen((event) {
      if (!_accelerometerEnabled || !mounted) return;
      final magnitude = math.sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );
      if (magnitude < 12.0) return;
      final now = DateTime.now();
      if (now.difference(_lastShakeTime) < const Duration(milliseconds: 1500)) {
        return;
      }
      _lastShakeTime = now;
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  void _evaluateMotionAndTilt() {
    if (!_hasBaseline || !_gyroscopeEnabled || !mounted) return;

    // Selisih kemiringan relatif terhadap posisi awal
    final deltaAccX = _currentAccX - _baseAccX;
    final deltaAccY = _currentAccY - _baseAccY;

    // Kecepatan sudut rotasi (pitch & roll)
    final gyroPitch =
        _currentGyroX; // Rotasi sumbu X (gerakan ke depan/belakang)
    final gyroRoll = _currentGyroY; // Rotasi sumbu Y (kemiringan ke kiri/kanan)

    // Gabungan sinyal kemiringan & goyangan dinamis
    // Sumbu X: Kiri (-) vs Kanan (+)
    final signalX = deltaAccX + (gyroRoll * 1.0);
    // Sumbu Y: Depan/Atas (-) vs Belakang/Bawah (+)
    final signalY = deltaAccY + (gyroPitch * 1.0);

    const double triggerThreshold = 2.0;
    const double neutralThreshold = 0.8;

    final absX = signalX.abs();
    final absY = signalY.abs();

    // Deteksi kembali ke posisi netral/center
    if (absX < neutralThreshold && absY < neutralThreshold) {
      _isNeutral = true;
      return;
    }

    if (absX >= triggerThreshold || absY >= triggerThreshold) {
      final now = DateTime.now();
      int targetIndex = -1;
      String directionName = '';
      IconData icon = Icons.touch_app;

      if (absY > absX) {
        // Gerakan sumbu vertikal lebih dominan
        if (signalY < -triggerThreshold) {
          // Gerakan ke depan -> Tilt Depan / Atas terpilih
          targetIndex = 2;
          directionName = 'Tilt Depan / Atas';
          icon = Icons.arrow_upward_rounded;
        } else if (signalY > triggerThreshold) {
          // Gerakan ke belakang -> Tilt Belakang / Bawah terpilih
          targetIndex = 3;
          directionName = 'Tilt Belakang / Bawah';
          icon = Icons.arrow_downward_rounded;
        }
      } else {
        // Gerakan sumbu horizontal lebih dominan
        if (signalX > triggerThreshold) {
          // Dimiringkan ke kiri -> Ke Kiri terpilih
          targetIndex = 0;
          directionName = 'Ke Kiri';
          icon = Icons.arrow_back_rounded;
        } else if (signalX < -triggerThreshold) {
          // Dimiringkan ke kanan -> Ke Kanan terpilih
          targetIndex = 1;
          directionName = 'Ke Kanan';
          icon = Icons.arrow_forward_rounded;
        }
      }

      if (targetIndex != -1) {
        final isDifferent = targetIndex != _selectedTilt;
        final cooldownPassed =
            now.difference(_lastTriggerTime) >
            const Duration(milliseconds: 1000);

        if (_isNeutral || isDifferent || cooldownPassed) {
          _isNeutral = false;
          _lastTriggerTime = now;
          _onSelectAnswer(
            targetIndex,
            directionName: directionName,
            icon: icon,
            fromSensor: true,
          );
        }
      }
    }
  }

  void _onSelectAnswer(
    int index, {
    required String directionName,
    required IconData icon,
    bool fromSensor = true,
  }) {
    if (!mounted) return;

    setState(() {
      _selectedTilt = index;
    });

    final answerText = (index >= 0 && index < _tiltControllers.length)
        ? _tiltControllers[index].text.trim()
        : 'Opsi ${index + 1}';
    final displayText = answerText.isNotEmpty
        ? answerText
        : 'Opsi ${index + 1}';

    // Haptic feedback
    HapticFeedback.mediumImpact();

    // Notifikasi visual in-app (floating SnackBar)
    final color = CreateQuizQuestionStyles
        .answerColors[index % CreateQuizQuestionStyles.answerColors.length];
  }

  String _getDirectionName(int index) {
    switch (index) {
      case 0:
        return 'Ke Kiri';
      case 1:
        return 'Ke Kanan';
      case 2:
        return 'Tilt Depan / Atas';
      case 3:
        return 'Tilt Belakang / Bawah';
      default:
        return '';
    }
  }

  IconData _getDirectionIcon(int index) {
    switch (index) {
      case 0:
        return Icons.arrow_back_rounded;
      case 1:
        return Icons.arrow_forward_rounded;
      case 2:
        return Icons.arrow_upward_rounded;
      case 3:
        return Icons.arrow_downward_rounded;
      default:
        return Icons.touch_app_rounded;
    }
  }

  @override
  void dispose() {
    _stopGyroscopeDetection();
    _shakeSub?.cancel();
    for (final controller in _tiltControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.space8,
            left: AppSpacing.space9,
            right: AppSpacing.space9,
            bottom: AppSpacing.fabClearance,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AccelerometerCard(
                enabled: _accelerometerEnabled,
                onChanged: _toggleAccelerometer,
              ),
              const SizedBox(height: AppSpacing.space8),
              _GyroscopeCard(
                enabled: _gyroscopeEnabled,
                onChanged: _toggleGyroscope,
                selectedTilt: _selectedTilt,
                onTiltSelected: (index) => _onSelectAnswer(
                  index,
                  directionName: _getDirectionName(index),
                  icon: _getDirectionIcon(index),
                  fromSensor: false,
                ),
                tiltControllers: _tiltControllers,
                onRecalibrate: _recalibrateInitialPosition,
                isCalibrated: _hasBaseline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SensorToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _SensorToggle({
    required this.value,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onChanged != null;

    return Semantics(
      button: true,
      enabled: interactive,
      toggled: value,
      child: Opacity(
        opacity: enabled ? ProfileTheme.toggleEnabledOpacity : 0.5,
        child: GestureDetector(
          onTap: interactive ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: ProfileTheme.toggleDuration,
            curve: ProfileTheme.toggleCurve,
            width: AppSizes.profileToggleWidth,
            height: AppSizes.profileToggleHeight,
            padding: ProfileTheme.paddingSmall,
            decoration: ProfileTheme.toggleDecoration(active: value),
            child: AnimatedAlign(
              duration: ProfileTheme.toggleDuration,
              curve: ProfileTheme.toggleCurve,
              alignment: value
                  ? ProfileTheme.toggleActiveAlignment
                  : ProfileTheme.toggleInactiveAlignment,
              child: Container(
                width: AppSizes.profileToggleKnob,
                height: AppSizes.profileToggleKnob,
                decoration: ProfileTheme.toggleKnobDecoration,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AccelerometerCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _AccelerometerCard({required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ProfileTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Aktifkan\nAccelerometer',
                    style: AppTextStyles.heading6.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                _SensorToggle(
                  value: enabled,
                  enabled: true,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'Ekspresikan mood-mu! Goyangkan smartphone kamu saat live room atau active question untuk melempar reaction emote (🔥, 🎉, ⚡, 🤯) secara instan ke layar peserta lain.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.43,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space6,
                vertical: AppSpacing.space3,
              ),
              decoration: ShapeDecoration(
                color: AppColors.primarySoft,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                shadows: AppShadows.hairlineTight,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.vibration_rounded,
                    size: AppIconSize.sm,
                    color: AppColors.locationInk,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Text(
                    enabled
                        ? 'Coba Shake Smartphone'
                        : 'Aktifkan Accelerometer untuk Mencoba',
                    style: AppTextStyles.labelStrongSmall.copyWith(
                      color: AppColors.locationInk,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GyroscopeCard extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final int selectedTilt;
  final ValueChanged<int> onTiltSelected;
  final List<TextEditingController> tiltControllers;
  final VoidCallback onRecalibrate;
  final bool isCalibrated;

  const _GyroscopeCard({
    required this.enabled,
    required this.onChanged,
    required this.selectedTilt,
    required this.onTiltSelected,
    required this.tiltControllers,
    required this.onRecalibrate,
    required this.isCalibrated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ProfileTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Aktifkan\nGyroscope',
                    style: AppTextStyles.heading6.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                _SensorToggle(
                  value: enabled,
                  enabled: true,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'Kemiringan ponsel untuk memilih opsi jawaban cepat saat kuis berlangsung.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.43,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orientasi Tilt Real-Time:',
                  style: AppTextStyles.labelStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (enabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space3,
                      vertical: AppSpacing.space1,
                    ),
                    decoration: BoxDecoration(
                      color: CreateQuizQuestionStyles
                          .answerColors[selectedTilt %
                              CreateQuizQuestionStyles.answerColors.length]
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            CreateQuizQuestionStyles.answerColors[selectedTilt %
                                CreateQuizQuestionStyles.answerColors.length],
                        width: 1,
                      ),
                    ),
                    child: Text(
                      selectedTilt == 0
                          ? '⬅ Kiri'
                          : selectedTilt == 1
                          ? '➡ Kanan'
                          : selectedTilt == 2
                          ? '⬆ Depan'
                          : '⬇ Belakang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            CreateQuizQuestionStyles.answerColors[selectedTilt %
                                CreateQuizQuestionStyles.answerColors.length],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
            Column(
              children: [
                for (var i = 0; i < tiltControllers.length; i++) ...[
                  QuizAnswerField(
                    optionIndex: i,
                    controller: tiltControllers[i],
                    correctIdx: selectedTilt,
                    onCorrectChanged: onTiltSelected,
                    readOnly: true,
                  ),
                  if (i < tiltControllers.length - 1)
                    const SizedBox(height: AppSpacing.space4),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.space8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: enabled ? onRecalibrate : () => onChanged(true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space6,
                    vertical: AppSpacing.space3,
                  ),
                  decoration: ShapeDecoration(
                    color: AppColors.primarySoft,
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
                    shadows: AppShadows.hairlineTight,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        enabled
                            ? (isCalibrated
                                  ? Icons.screen_rotation_alt_rounded
                                  : Icons.refresh_rounded)
                            : Icons.touch_app_rounded,
                        size: AppIconSize.sm,
                        color: AppColors.locationInk,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Text(
                        enabled
                            ? (!isCalibrated
                                  ? 'Belum digunakan'
                                  : 'Coba miringkan smartphone')
                            : 'Aktifkan Gyroscope untuk Mencoba',
                        style: AppTextStyles.labelStrongSmall.copyWith(
                          color: AppColors.locationInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
