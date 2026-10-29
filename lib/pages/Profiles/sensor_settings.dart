import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../helpers/gyro_tilt_service.dart';
import '../../helpers/shake_service.dart';
import '../../services/api/location_service.dart';
import '../../services/profile_settings_service.dart';
import '../../services/session_service.dart';
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
      appBar: AppHeaderBarWithActions(
        title: title,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
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
  bool _locationEnabled = false;
  bool _locationBusy = false;
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
    final loc = await LocationService.instance.isEnabled();
    await _gyroService.init();
    if (!mounted) return;
    setState(() {
      _accelerometerEnabled = acc;
      _gyroscopeEnabled = gyro;
      _locationEnabled = loc;
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

  Future<void> _toggleLocation(bool value) async {
    if (!value) {
      setState(() => _locationEnabled = false);
      await LocationService.instance.setEnabled(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lokasi wilayah dinonaktifkan.'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 1500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _locationBusy = true);
    try {
      final access = await LocationService.ensurePermission();
      if (!mounted) return;
      if (access != LocationAccess.granted) {
        if (access == LocationAccess.serviceDisabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'GPS tidak aktif. Aktifkan layanan lokasi perangkat.',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else if (access == LocationAccess.deniedForever) {
          LocationService.openSettings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Izin lokasi ditolak.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }

      final token = await SessionService.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await LocationService.instance.locate(token: token);
      }
      await LocationService.instance.setEnabled(true);
      if (!mounted) return;
      setState(() => _locationEnabled = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lokasi wilayah berhasil diaktifkan!'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _locationBusy = false);
    }
  }

  void _recalibrateInitialPosition() {
    if (!_gyroscopeEnabled) return;
    setState(() {
      _gyroService.recalibrate();
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
    _gyroService.start(
      cooldown: const Duration(milliseconds: 1000),
      onCalibrated: () {
        if (mounted) {
          setState(() {});
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
      },
      onTilt: (event) {
        if (!_gyroscopeEnabled || !mounted) return;
        _onSelectAnswer(
          event.index,
          directionName: event.directionName,
          icon: event.icon,
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

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '$directionName terpilih: $displayText',
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
                isCalibrated: _gyroService.hasBaseline,
              ),
              const SizedBox(height: AppSpacing.space8),
              _LocationCard(
                enabled: _locationEnabled,
                busy: _locationBusy,
                onChanged: _toggleLocation,
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

class _LocationCard extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _LocationCard({
    required this.enabled,
    required this.busy,
    required this.onChanged,
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
                    'Aktifkan\nLokasi (GPS)',
                    style: AppTextStyles.heading6.copyWith(
                      color: AppColors.textPrimary,
                      height: 1.25,
                    ),
                  ),
                ),
                _SensorToggle(
                  value: enabled,
                  enabled: !busy,
                  onChanged: onChanged,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              'Gunakan sensor lokasi untuk menampilkan leaderboard peringkat wilayah (kecamatan, kota, provinsi). Sekali diaktifkan, lokasi akan tetap berlaku hingga dimatikan sendiri.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.43,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
