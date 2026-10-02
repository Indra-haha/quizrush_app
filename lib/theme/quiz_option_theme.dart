import 'package:flutter/material.dart';

import 'app_theme.dart';

class QuizOptionTheme {
  final Color bg;
  final Color border;
  final Color dot;
  final String hint;

  const QuizOptionTheme({
    required this.bg,
    required this.border,
    required this.dot,
    required this.hint,
  });
}

const List<QuizOptionTheme> optionThemes = [
  QuizOptionTheme(
    bg: AppColors.answerRedSoft,
    border: AppColors.answerRedBorder,
    dot: AppColors.answerRed,
    hint: 'Jawaban merah...',
  ),
  QuizOptionTheme(
    bg: AppColors.answerBlueSoft,
    border: AppColors.answerBlueBorder,
    dot: AppColors.answerBlue,
    hint: 'Jawaban biru...',
  ),
  QuizOptionTheme(
    bg: AppColors.answerYellowSoft,
    border: AppColors.answerYellowBorder,
    dot: AppColors.answerYellow,
    hint: 'Jawaban kuning...',
  ),
  QuizOptionTheme(
    bg: AppColors.answerGreenSoft,
    border: AppColors.answerGreenBorder,
    dot: AppColors.answerGreen,
    hint: 'Jawaban hijau...',
  ),
];
