import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Font sizes exposed for widget APIs that take a raw size.
class AppFontSize {
  AppFontSize._();

  static const caption = 10.0;
  static const micro = 11.0;
  static const small = 12.0;
  static const body = 13.0;
  static const bodyLarge = 14.0;
  static const medium = 15.0;
  static const base = 16.0;
  static const title = 18.0;
  static const heading = 22.0;
  static const display = 24.0;
  static const hero = 36.0;
}

/// Font weights exposed for widget APIs that take a raw weight.
class AppFontWeight {
  AppFontWeight._();

  static const regular = FontWeight.w400;
  static const medium = FontWeight.w500;
  static const semibold = FontWeight.w600;
  static const bold = FontWeight.w700;
  static const extrabold = FontWeight.w800;
  static const black = FontWeight.w900;
}

/// Text styles. Setiap widget dan halaman WAJIB membaca tipografi dari sini.
class AppTextStyles {
  AppTextStyles._();

  static final bodyMediumOnPrimary = GoogleFonts.plusJakartaSans(
    color: AppColors.textOnPrimary,
    fontSize: 14,
    height: 1.43,
    letterSpacing: 0.1,
  );

  /// Monospace room code badge.
  static final roomCode = TextStyle(
    fontFamily: 'monospace',
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    height: 1.33,
    letterSpacing: 0.6,
  );

  /// Answer option letter badge.
  static final optionLetter = TextStyle(
    color: AppColors.textOnPrimary,
    fontWeight: FontWeight.w700,
    fontSize: 16,
    height: 1.2,
  );

  static final heading1Strong = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.27,
  );

  static final heading1StrongAccent = GoogleFonts.montserrat(
    color: AppColors.primary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.27,
  );

  static final heading2Strong = GoogleFonts.montserrat(
    color: AppColors.primary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.21,
  );

  static final calculatorDisplay = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static final calculatorResult = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  static final cardTitle = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static final heroTitle = GoogleFonts.montserrat(
    color: AppColors.primary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: 1.2,
  );

  static final hintLarge = GoogleFonts.plusJakartaSans(
    color: AppColors.textMuted,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static final hint = GoogleFonts.plusJakartaSans(
    color: AppColors.textMuted,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static final hintSmall = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 1,
  );

  static final code = TextStyle(
    fontFamily: 'monospace',
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    letterSpacing: 4,
  );

  static final displayHero = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.17,
    letterSpacing: -0.4,
  );

  static final countdown = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.2,
  );

  static final display1 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.8,
  );

  /// Judul besar 36pt (hero halaman menunggu).
  static final displayTitle = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static final display2 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.17,
    letterSpacing: -0.4,
  );

  static final heading1 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.21,
  );

  static final heading2 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.27,
  );

  static final heading3 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.22,
  );

  static final heading4 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.56,
  );

  static final heading5 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static final heading6 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  static final statValue = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.17,
    letterSpacing: -0.4,
  );

  static final statValueOnPrimary = GoogleFonts.montserrat(
    color: AppColors.textOnPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.17,
    letterSpacing: -0.4,
  );

  static final statLabelOnPrimary = GoogleFonts.plusJakartaSans(
    color: AppColors.textOnPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static final bodyLarge = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static final bodyMedium = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static final body = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static final bodySmall = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static final bodyMeta = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static final bodyCaption = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  /// Judul kartu quiz berkelompok (desain MyQuiz).
  static final quizGroupTitle = GoogleFonts.plusJakartaSans(
    color: AppColors.inkStrong,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// Meta mikro: durasi/soal, label pill jumlah room (desain MyQuiz).
  static final metaMicro = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.27,
    letterSpacing: 0.33,
  );

  static final labelStrong = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
  );

  static final labelStrongOnPrimary = GoogleFonts.plusJakartaSans(
    color: AppColors.textOnPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
  );

  static final labelStrongError = GoogleFonts.plusJakartaSans(
    color: AppColors.error,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
  );

  static final labelStrongSmall = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  static final labelStrongSmallOnPrimary = GoogleFonts.plusJakartaSans(
    color: AppColors.textOnPrimary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  static final buttonLarge = GoogleFonts.plusJakartaSans(
    color: AppColors.textOnPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static final button = GoogleFonts.plusJakartaSans(
    color: AppColors.textOnPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );

  static final buttonSmall = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  static final accentLabel = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.43,
  );

  static final accentCaption = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: 0.6,
  );

  static final metric = GoogleFonts.plusJakartaSans(
    color: AppColors.info,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.36,
  );

  static final metricStrong = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: 1.2,
  );
}
