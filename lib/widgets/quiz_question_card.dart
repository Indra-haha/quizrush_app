import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu teks pertanyaan (dipakai halaman testing kuis).
class QuizQuestionCard extends StatelessWidget {
  final String question;

  const QuizQuestionCard({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.hairlineWide,
      ),
      child: Center(
        child: Text(
          question,
          textAlign: TextAlign.center,
          style: AppTextStyles.heading6,
        ),
      ),
    );
  }
}
