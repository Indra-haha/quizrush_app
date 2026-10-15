import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_pill.dart';
import 'app_stat_tile.dart';

/// Header halaman testing kuis: judul kuis, progres soal, dan skor.
class QuizTestHeader extends StatelessWidget {
  final String title;
  final int currentIndex;
  final int totalQuestions;
  final int maxScore;
  final int totalScore;

  const QuizTestHeader({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.totalQuestions,
    required this.maxScore,
    required this.totalScore,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.space2,
        bottom: AppSpacing.space6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: AppTextStyles.labelStrongSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              AppPill(
                text: 'Soal ${currentIndex + 1}',
                trailingText: '/ $totalQuestions',
                trailingColor: AppColors.textSecondary,
                background: AppColors.surfaceSoft,
                foreground: AppColors.textPrimary,
                dot: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space2,
                ),
              ),
            ],
          ),
          Row(
            children: [
              AppStatTile.compact(
                value: 'Max $maxScore pts',
                bg: AppColors.surfaceSoft,
                fg: AppColors.textSecondary,
                borderColor: AppColors.divider,
              ),
              const SizedBox(width: AppSpacing.space4),
              AppStatTile.compact(
                value: '$totalScore',
                bg: AppColors.surface,
                fg: AppColors.textPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
