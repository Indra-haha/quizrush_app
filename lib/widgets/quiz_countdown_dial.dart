import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dial hitung mundur berbentuk lingkaran. Warna berubah ke merah saat sisa
/// waktu tiga detik terakhir.
class QuizCountdownDial extends StatelessWidget {
  final int seconds;
  final int urgentSeconds;

  const QuizCountdownDial({
    super.key,
    required this.seconds,
    this.urgentSeconds = 3,
  });

  bool get _isUrgent => seconds <= urgentSeconds;

  @override
  Widget build(BuildContext context) {
    final accent = _isUrgent ? AppColors.error : AppColors.primary;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: AppBorderWidth.heavy),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$seconds',
            style: AppTextStyles.heading1.copyWith(
              color: _isUrgent ? AppColors.error : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text('DETIK', style: AppTextStyles.hintSmall),
        ],
      ),
    );
  }
}
