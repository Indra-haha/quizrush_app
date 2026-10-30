import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../helpers/gyro_tilt_service.dart';
import '../../helpers/shake_service.dart';
import '../../services/profile_settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/quiz_question_editor.dart';

class SensorSettingsPage extends StatelessWidget {
  const SensorSettingsPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar:  AppHeaderBarWithActions(
        title: 'Pengaturan Sensor',
        titleStyle: CreateQuizTextStyles.headerTitle,
        backgroundColor: CreateQuizPageStyles.headerBackground,
        elevation: CreateQuizPageStyles.headerElevation,
        shadowColor: CreateQuizPageStyles.headerShadowColor,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back),
        ),
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
  int? _selectedTilt;
  TiltAngleInfo? _currentAngleInfo;

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

  final GyroTiltService _gyroService = GyroTiltService();
  StreamSubscription<ShakeReading>? _shakeSub;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ProfileSettingsService.instance;
    final acc = await service.accelerometerEnabled();
    final gyro = await service.gyroscopeEnabled();
    await _gyroService.init();
    if (!mounted) return;
    setState(() {
      _accelerometerEnabled = acc;
      _gyroscopeEnabled = gyro;
      _selectedTilt = null;
    });

    if (acc) {
      _startShakeDetection();
    }
    if (gyro) {
      _startGyroscopeDetection();
      // Rekam posisi awal awal saat dibuka agar 0° sesuai genggaman pengguna saat ini
      _recalibrateInitialPosition(showSnackbar: false);
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
    setState(() {
      _gyroscopeEnabled = value;
      _selectedTilt = null;
    });
    await ProfileSettingsService.instance.setGyroscopeEnabled(value);
    if (value) {
      _startGyroscopeDetection(notifyOnReady: true);
      _recalibrateInitialPosition(showSnackbar: false);
    } else {
      _stopGyroscopeDetection();
    }
  }

  void _recalibrateInitialPosition({bool showSnackbar = true}) {
    if (!_gyroscopeEnabled) return;
    setState(() {
      _selectedTilt = null;
      _gyroService.recalibrate();
    });

    HapticFeedback.lightImpact();

    if (!mounted || !showSnackbar) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.crop_rotate_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Merekam posisi awal... Tahan ponsel di posisi nyaman.',
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
    _gyroService.start(
      triggerAngle: 15.0,
      neutralAngle: 8.0,
      cooldown: const Duration(milliseconds: 800),
      onAngleUpdate: (info) {
        if (!mounted) return;
        setState(() {
          _currentAngleInfo = info;
        });
      },
      onCalibrated: () {
        if (mounted) {
          setState(() {
            _selectedTilt = null;
          });
        }
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
                      'Posisi awal (0°) disimpan! Miringkan ponsel min. 15° untuk memilih opsi jawaban.',
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
      },
      onTilt: (event) {
        if (!_gyroscopeEnabled || !mounted) return;
        _onSelectAnswer(
          event.index,
          directionName: event.directionName,
          icon: event.icon,
          angle: event.angleDegrees,
          fromSensor: true,
        );
      },
    );
  }

  void _stopGyroscopeDetection() {
    _gyroService.stop();
  }

  void _startShakeDetection() {
    _shakeSub?.cancel();
    _shakeSub = ShakeService.instance
        .shakeEvents(
          threshold: 12.0,
          cooldown: const Duration(milliseconds: 1500),
        )
        .listen(
          (_) {
            if (!_accelerometerEnabled || !mounted) return;
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          onError: (_) {
            _shakeSub?.cancel();
            _shakeSub = null;
          },
          cancelOnError: true,
        );
  }

  void _onSelectAnswer(
    int index, {
    required String directionName,
    required IconData icon,
    double? angle,
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

    final angleText = (angle != null && angle > 0)
        ? ' (${angle.toStringAsFixed(1)}°)'
        : '';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$directionName$angleText terpilih: $displayText',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    _gyroService.dispose();
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
            left: AppSpacing.space8,
            right: AppSpacing.space8,
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
                onRecalibrate: () => _recalibrateInitialPosition(showSnackbar: true),
                isCalibrated: _gyroService.hasBaseline,
                angleInfo: _currentAngleInfo,
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
  final int? selectedTilt;
  final ValueChanged<int> onTiltSelected;
  final List<TextEditingController> tiltControllers;
  final VoidCallback onRecalibrate;
  final bool isCalibrated;
  final TiltAngleInfo? angleInfo;

  const _GyroscopeCard({
    required this.enabled,
    required this.onChanged,
    required this.selectedTilt,
    required this.onTiltSelected,
    required this.tiltControllers,
    required this.onRecalibrate,
    required this.isCalibrated,
    this.angleInfo,
  });

  Widget _buildRealtimeBadge() {
    final info = angleInfo;
    if (info == null || info.isCalibrating || !isCalibrated) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sync_rounded,
              size: 13,
              color: AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Merekam Posisi...',
              style: AppTextStyles.labelStrongSmall.copyWith(
                color: AppColors.primary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }

    if (info.direction != null) {
      final dir = info.direction!;
      final color = CreateQuizQuestionStyles
          .answerColors[dir.index % CreateQuizQuestionStyles.answerColors.length];
      final label = dir == TiltDirection.forward
          ? '⬆ Depan (${info.dominantAngle.toStringAsFixed(0)}°)'
          : dir == TiltDirection.backward
          ? '⬇ Belakang (${info.dominantAngle.toStringAsFixed(0)}°)'
          : dir == TiltDirection.left
          ? '⬅ Kiri (${info.dominantAngle.toStringAsFixed(0)}°)'
          : '➡ Kanan (${info.dominantAngle.toStringAsFixed(0)}°)';

      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space3,
          vertical: AppSpacing.space1,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primaryBorder),
      ),
      child: Text(
        '⚪ Netral (< 15°)',
        style: AppTextStyles.labelStrongSmall.copyWith(
          color: AppColors.textSecondary,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildDegreeStatusBox() {
    final isCalibrating = angleInfo?.isCalibrating ?? false;
    final dominant = angleInfo?.dominantAngle ?? 0.0;
    final currentDir = angleInfo?.direction;
    final targetAngle = angleInfo?.triggerAngle ?? 15.0;
    final progress = (dominant / targetAngle).clamp(0.0, 1.0);

    String statusText;
    String detailText;
    Color statusColor;

    if (isCalibrating || !isCalibrated) {
      statusText = 'Merekam posisi awal ponsel (0°)...';
      detailText = 'Tahan smartphone di posisi membaca yang nyaman.';
      statusColor = AppColors.primary;
    } else if (currentDir != null) {
      final dirName = currentDir == TiltDirection.forward
          ? 'Tilt Depan'
          : currentDir == TiltDirection.backward
          ? 'Tilt Belakang'
          : currentDir == TiltDirection.left
          ? 'Miring Kiri'
          : 'Miring Kanan';
      statusText = '$dirName: ${dominant.toStringAsFixed(1)}° (≥ 15°) Terdeteksi!';
      detailText = 'Opsi jawaban telah dipilih otomatis oleh sensor.';
      statusColor = CreateQuizQuestionStyles
          .answerColors[currentDir.index % CreateQuizQuestionStyles.answerColors.length];
    } else {
      statusText = 'Posisi Netral: ${dominant.toStringAsFixed(1)}° (Target min. 15.0°)';
      detailText = 'Miringkan ponsel minimal 15° ke salah satu arah untuk menjawab.';
      statusColor = AppColors.textSecondary;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                currentDir != null
                    ? currentDir.icon
                    : Icons.screen_lock_rotation_rounded,
                size: 16,
                color: statusColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  statusText,
                  style: AppTextStyles.labelStrongSmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detailText,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primaryBorder.withValues(alpha: 0.3),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

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
              'Kemiringan ponsel untuk memilih opsi jawaban cepat saat kuis berlangsung (kemiringan minimal 15°).',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.43,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Orientasi Tilt Real-Time:',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                if (enabled) _buildRealtimeBadge(),
              ],
            ),
            if (enabled) ...[
              const SizedBox(height: AppSpacing.space4),
              _buildDegreeStatusBox(),
            ],
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
                            ? Icons.crop_rotate_rounded
                            : Icons.touch_app_rounded,
                        size: AppIconSize.sm,
                        color: AppColors.locationInk,
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Text(
                        enabled
                            ? 'Rekam Posisi Awal (Kalibrasi 0°)'
                            : 'Aktifkan Gyroscope untuk Kalibrasi',
                        style: AppTextStyles.labelStrongSmall.copyWith(
                          color: AppColors.locationInk,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (enabled) ...[
              const SizedBox(height: AppSpacing.space2),
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.space2),
                child: Text(
                  'Tips: Pegang ponsel di posisi nyaman Anda, lalu tekan tombol di atas untuk merekam posisi awal 0°. Gerakkan minimal 15° untuk memilih jawaban.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

