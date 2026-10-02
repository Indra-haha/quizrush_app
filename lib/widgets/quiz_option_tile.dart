import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/quiz_option_theme.dart';

/// Kondisi visual satu pilihan jawaban setelah user menjawab.
enum QuizOptionState { idle, selected, correct, wrong, dimmed }

/// Baris pilihan jawaban pada halaman test quiz: huruf opsi, teks jawaban, dan
/// warna umpan balik. Widget ini tidak tahu apa pun soal timer atau skor.
class QuizOptionTile extends StatelessWidget {
  final String label;
  final String letter;
  final QuizOptionTheme theme;
  final QuizOptionState state;
  final VoidCallback? onTap;

  const QuizOptionTile({
    super.key,
    required this.label,
    required this.letter,
    required this.theme,
    required this.state,
    this.onTap,
  });

  Color get _background {
    switch (state) {
      case QuizOptionState.correct:
        return AppColors.success;
      case QuizOptionState.wrong:
        return AppColors.errorSoft;
      case QuizOptionState.dimmed:
        return theme.bg.withValues(alpha: 0.4);
      case QuizOptionState.selected:
        return Color.alphaBlend(
          AppColors.textPrimary.withValues(alpha: 0.15),
          theme.bg,
        );
      case QuizOptionState.idle:
        return theme.bg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 84,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: _background,
            border: Border.all(
              color: theme.border,
              width: AppBorderWidth.heavy,
            ),
            borderRadius: AppRadius.md,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.dot,
                  borderRadius: AppRadius.md,
                ),
                child: Text(letter, style: AppTextStyles.optionLetter),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.button.copyWith(color: theme.border),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
