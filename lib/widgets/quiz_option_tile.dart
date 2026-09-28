import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        return AppColors.successSoft;
      case QuizOptionState.wrong:
        return AppColors.dangerSoft;
      case QuizOptionState.dimmed:
        return theme.bg.withValues(alpha: 0.4);
      case QuizOptionState.selected:
        return Color.alphaBlend(
          Colors.black.withValues(alpha: 0.15),
          theme.bg,
        );
      case QuizOptionState.idle:
        return theme.bg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _background,
            border: Border.all(color: theme.border, width: 4),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.dot,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: theme.border,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
