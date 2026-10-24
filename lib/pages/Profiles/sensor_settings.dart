import 'package:flutter/material.dart';

import '../../services/profile_settings_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/points_indicator.dart';
import '../../widgets/quiz_question_editor.dart';
import '../../widgets/compass_calibration_modal.dart';


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

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = ProfileSettingsService.instance;
    final acc = await service.accelerometerEnabled();
    final gyro = await service.gyroscopeEnabled();
    if (!mounted) return;
    setState(() {
      _accelerometerEnabled = acc;
      _gyroscopeEnabled = gyro;
    });
  }

  Future<void> _toggleAccelerometer(bool value) async {
    setState(() => _accelerometerEnabled = value);
    await ProfileSettingsService.instance.setAccelerometerEnabled(value);
  }

  Future<void> _toggleGyroscope(bool value) async {
    setState(() => _gyroscopeEnabled = value);
    await ProfileSettingsService.instance.setGyroscopeEnabled(value);
    if (value && mounted) {
      await showCompassCalibrationModal(context);
    }
  }

  @override
  void dispose() {
    for (final controller in _tiltControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
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
                onTiltSelected: (index) =>
                    setState(() => _selectedTilt = index),
                tiltControllers: _tiltControllers,
              ),
            ],
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
                    'Coba Shake Smartphone',
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

  const _GyroscopeCard({
    required this.enabled,
    required this.onChanged,
    required this.selectedTilt,
    required this.onTiltSelected,
    required this.tiltControllers,
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
            Text(
              'Orientasi Tilt Real-Time:',
              style: AppTextStyles.labelStrong.copyWith(
                color: AppColors.textPrimary,
              ),
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
                  ),
                  if (i < tiltControllers.length - 1)
                    const SizedBox(height: AppSpacing.space4),
                ],
              ],
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
                    Icons.screen_rotation_alt_rounded,
                    size: AppIconSize.sm,
                    color: AppColors.locationInk,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Text(
                    'Coba Miringkan Smartphone',
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
