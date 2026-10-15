import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../theme/quiz_option_theme.dart';
import '../helpers/format.dart';
import 'app_pill.dart';

/// Warna huruf pilihan jawaban pada kartu pratinjau (urutan biru, kuning,
/// hijau, merah).
final _optionColors = [
  optionThemes[1].dot,
  optionThemes[2].dot,
  optionThemes[3].dot,
  optionThemes[0].dot,
];

/// Kartu pratinjau satu pertanyaan (read-only) untuk halaman detail room.
class QuizQuestionPreviewCard extends StatelessWidget {
  final QuizQuestion question;
  final int index;

  const QuizQuestionPreviewCard({
    super.key,
    required this.question,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.layeredCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                text: 'Soal ${index + 1}',
                background: AppColors.primary,
                foreground: AppColors.textOnPrimary,
              ),
              const SizedBox(width: AppSpacing.space4),
              AppPill(
                text: formatQDuration(question.duration),
                background: AppColors.surfaceSoft,
                foreground: AppColors.textSecondary,
              ),
              const Spacer(),
              Text(
                '${question.skor} Pts',
                style: AppTextStyles.statLabelOnPrimary.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            question.question,
            style: AppTextStyles.buttonLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          for (final (i, option) in question.options.indexed) ...[
            _optionTile(option, i),
            if (i < question.options.length - 1)
              const SizedBox(height: AppSpacing.space4),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(String option, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _optionColors[index % _optionColors.length],
              borderRadius: AppRadius.md,
            ),
            child: Text(
              String.fromCharCode(65 + index),
              style: AppTextStyles.labelStrongSmall.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space1),
              child: Text(option, style: AppTextStyles.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }
}
