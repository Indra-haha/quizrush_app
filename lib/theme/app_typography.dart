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

  static final cardTitle = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
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

  static final display1 = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 40,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.8,
  );

  /// Sapaan besar beranda (desain baru).
  static final homeGreeting = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 36,
    fontWeight: FontWeight.w800,
    height: 1.33,
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

  /// Label kecil untuk nilai statistik.
  static final labelSmall = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  static final homeStatLabelOnPrimary = GoogleFonts.plusJakartaSans(
    color: AppColors.onPrimaryMuted,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
  );

  /// Nilai kartu statistik beranda (desain baru).
  static final homeStatValue = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static final homeStatValueOnPrimary = GoogleFonts.montserrat(
    color: AppColors.onPrimaryMuted,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.4,
  );

  /// Tautan "Lihat Semua" pada judul section beranda.
  static final sectionLink = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Label tombol aksi beranda ("Create Quiz").
  static final fontButtonAction = GoogleFonts.montserrat(
    color: AppColors.textOnPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
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

  /// Wordmark QUIZRUSH pada hero halaman register.
  static final brandWordmark = GoogleFonts.montserrat(
    color: AppColors.primary,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontStyle: FontStyle.italic,
    height: 1.06,
    letterSpacing: -1.4,
  );

  /// Tagline di bawah wordmark.
  static final heroTagline = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Judul kartu form auth ("Buat Akun").
  static final authTitle = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.6,
    letterSpacing: -0.6,
  );

  /// Label field form (di atas kotak input).
  static final fieldLabel = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Isi field form.
  static final fieldValue = GoogleFonts.plusJakartaSans(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Placeholder field form.
  static final fieldHint = GoogleFonts.plusJakartaSans(
    color: AppColors.fieldHint,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  /// Placeholder field form Create Quiz (desain baru).
  static final quizFieldHint = GoogleFonts.montserrat(
    color: AppColors.fieldHint,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  /// Label tombol utama halaman auth.
  static final authAction = GoogleFonts.montserrat(
    color: AppColors.textOnPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
    letterSpacing: -0.6,
  );

  /// Teks sekunder berukuran body.
  static final bodySecondary = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Tautan syarat & ketentuan (garis bawah).
  static final termsLink = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    decoration: TextDecoration.underline,
  );

  /// Tautan "Masuk di sini" di bawah kartu auth.
  static final authFooterLink = GoogleFonts.plusJakartaSans(
    color: AppColors.primary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.43,
  );

  /// Inisial nama pada avatar kartu profil.
  static final profileAvatarInitials = GoogleFonts.montserrat(
    color: AppColors.primary,
    fontSize: AppFontSize.hero,
    fontWeight: FontWeight.w700,
    height: 1,
  );

  /// Nama pengguna pada kartu profil.
  static final profileName = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.21,
    letterSpacing: -0.7,
  );

  /// Label pill kelas pada kartu profil.
  static final profileLocation = GoogleFonts.plusJakartaSans(
    color: AppColors.locationInk,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  /// Nilai statistik pada kartu profil.
  static final profileStatValue = GoogleFonts.montserrat(
    color: AppColors.textPrimary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  static final profileStatValueAccent = GoogleFonts.montserrat(
    color: AppColors.primary,
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.33,
  );

  /// Deskripsi baris pengaturan profil.
  static final settingSubtitle = GoogleFonts.plusJakartaSans(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.33,
  );
}
