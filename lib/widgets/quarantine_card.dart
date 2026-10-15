import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../theme/app_theme.dart';

class QuarantineCard extends StatelessWidget {
  final Quizes quiz;
  final VoidCallback? onTap;

  const QuarantineCard({super.key, required this.quiz, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.space8),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.primaryBorder),
          boxShadow: AppShadows.hairlineTight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space5,
                        vertical: AppSpacing.space1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary,
                        borderRadius: AppRadius.md,
                        border: Border.all(color: AppColors.primaryBorder),
                        boxShadow: AppShadows.hairlineTight,
                      ),
                      child: Text(
                        'Quarantine',
                        style: AppTextStyles.labelStrongSmall.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            if (quiz.title.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: Text(quiz.title, style: AppTextStyles.heading2),
              ),
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.space1),
              SizedBox(
                width: double.infinity,
                child: Text(quiz.description, style: AppTextStyles.bodyMeta),
              ),
            ],
            const SizedBox(height: AppSpacing.space5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: AppSpacing.space5),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.primaryBorder.withValues(alpha: 0.8),
                  ),
                ),
              ),
              child: Row(
                children: [
                  _durationChip(),
                  const SizedBox(width: AppSpacing.space2),
                  _gameChip(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _durationChip() {
    final minutes = quiz.durationSeconds.ceil();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.access_time,
          size: AppIconSize.xs,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.space2),
        Text('$minutes menit', style: AppTextStyles.labelStrongSmall),
      ],
    );
  }

  Widget _gameChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.primarySoft),
      ),
      child: Text(
        '${quiz.rooms.length} Game',
        style: AppTextStyles.labelStrongSmall.copyWith(
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}
