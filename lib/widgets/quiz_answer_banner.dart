import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final accent = isCorrect ? AppColors.successInk : AppColors.dangerInk;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isCorrect ? AppColors.successSoft : AppColors.dangerSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isCorrect ? Icons.check_circle : Icons.cancel,
            color: accent,
          ),
          const SizedBox(width: 8),
          Text(
            isCorrect
                ? 'Kamu Benar! (+$gainedScore Poin)'
                : 'Kamu Salah! (+0 Poin)',
            style: GoogleFonts.montserrat(
              color: accent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
