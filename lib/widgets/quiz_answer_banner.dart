import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Banner umpan balik setelah jawaban dipilih: hijau untuk benar, merah untuk
/// salah, lengkap dengan poin yang didapat.
class QuizAnswerBanner extends StatelessWidget {
  final bool isCorrect;
  final int gainedScore;

  const QuizAnswerBanner({
    super.key,
    required this.isCorrect,
    required this.gainedScore,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.space7,
        horizontal: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.success : AppColors.errorSoft,
        borderRadius: AppRadius.lg,
        border: Border.all(color: accent, width: AppBorderWidth.regular),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: accent),
          const SizedBox(width: AppSpacing.space4),
          Text(
            isCorrect
                ? 'Kamu Benar! (+$gainedScore Poin)'
                : 'Kamu Salah! (+0 Poin)',
            style: AppTextStyles.heading5.copyWith(color: accent),
          ),
        ],
      ),
    );
  }
}
