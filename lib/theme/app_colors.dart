import 'package:flutter/material.dart';

/// Color tokens.
///
/// Setiap widget dan halaman WAJIB membaca warna dari sini. Jangan menulis
/// nilai warna secara hardcoded di file lain.
class AppColors {
  AppColors._();

  // Primary
  static const primary = Color(0xFF4648D4);
  static const primaryDark = Color(0xFF4F46E5);
  static const primarySoft = Color(0xFFE1E0FF);
  static const primaryBorder = Color(0xFFC7C4D7);

  // Surface
  static const background = Color(0xFFF0EFFF);
  static const surface = Color(0xFFF9F9FF);
  static const surfaceSoft = Color(0xFFDEE8FF);

  //gradient
  static const gradientStart = Color(0xFF4648D4);
  static const gradientEnd = Color(0xFF6B38D4);

  // Putih murni (kartu form auth) & latar halaman auth (desain register).
  static const pureSurface = Color(0xFFFFFFFF);
  static const pageBase = Color(0xFFFCFCFC);
  static const fieldBackground = Color(0xFFF0F3FF);
  static const fieldHint = Color(0xFF9CA3AF);
  static const checkboxStroke = Color(0xFF767676);

  // Surface kanvas untuk halaman daftar quiz (desain MyQuiz).
  static const quizCanvas = Color(0xFFFBF8FF);

  // Profil: bidang navigasi bawah semi-transparan, tinta pill wilayah, dan
  // warna bayangan header.
  static const navSurface = Color(0xD8F9F9FF);
  static const locationInk = Color(0xFF07006C);
  static const headerShadow = Color(0x33000000);

  // Beranda (desain baru): tint ikon kartu statistik, overlay di atas gambar
  // kuis, dan border kartu kuis.
  static const homeTotalTint = primarySoft;
  static const homeHostTint = participantTile;
  static const homeUpdateTint = errorSoft;
  static const homeCardBorder = Color(0x4CC7C4D7);
  static const overlayLight = Color(0x33FFFFFF);
  static const overlayBorder = Color(0x4DFFFFFF);
  static const onPrimaryMuted = Color(0xE6FFFFFF);
  static const onPrimarySubtle = Color(0x99FFFFFF);
  static const onPrimarySoft = Color(0x73FFFFFF);
  static const onPrimaryFaint = Color(0x4DFFFFFF);
  static const onPrimaryWash = Color(0x1AFFFFFF);
  static const onPrimaryVeil = Color(0x33FFFFFF);
  static const onLightAlpha = Color(0x3DFFFFFF);

  // Reward: tinta nominal pada riwayat poin.
  static const rewardAmountInk = Color(0xFF825100);

  // Scrim/overlay di atas gambar cover Create Quiz.
  static const scrim = Color(0x8C111C2D);
  static const scrimSoft = Color(0x99111C2D);
  static const scrimStrong = Color(0xB3111C2D);

  // Aksen indigo (tombol aksi & pill utama pada desain MyQuiz).
  static const indigoAction = Color(0xFF4B49D6);
  static const indigoActionSoft = Color(0xFFE2DFFF);
  static const indigoActionInk = Color(0xFF362EB9);

  // Tint kartu & tile pada desain MyQuiz.
  static const tintIcon = Color(0xFFEEECFF);
  static const tintRoom = Color(0xFFF5F2FF);

  // Tinta tambahan.
  static const inkStrong = Color(0xFF171936);
  static const inkMuted = Color(0xFF777586);

  // Palet halaman menunggu (desain "test waiting"): chip meta di hero,
  // kartu peserta, dan avatar.
  static const heroLime = Color(0xFF96DB0A);
  static const heroPeach = Color(0xFFFFDDB8);
  static const participantTile = Color(0xFFE7EEFF);
  static const avatarSoft = Color(0xFFE9DDFF);
  static const accentOrange = Color(0xFFF57710);

  // Amber (badge WAITING pada desain MyQuiz).
  static const amberSoft = Color(0xFFFEF3C7);
  static const amberInk = Color(0xFF92400E);

  // Indigo tipis (badge SELESAI & tombol "Lihat Hasil" pada desain MyQuiz).
  static const endedTint = Color(0xFFE0E0FF);
  static const endedInk = Color(0xFF444557);

  // Text
  static const textPrimary = Color(0xFF111C2D);
  static const textSecondary = Color(0xFF464554);
  static const textMuted = Color(0xFF6B7280);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Status
  static const error = Color(0xFFBA1A1A);
  static const errorSoft = Color(0xFFFFDAD6);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF94A3B8);

  static const divider = Color(0xFFE2E8F0);

  // Answer-option palette (quiz). Pilihan jawaban wajib bisa dibedakan satu
  // sama lain, jadi warna ini dipertahankan sebagai token semantic.
  static const answerRed = Color(0xFFBA1A1A);
  static const answerRedSoft = Color(0xFFFFDAD6);
  static const answerRedBorder = Color(0xFF93000A);

  static const answerBlue = Color(0xFF4648D4);
  static const answerBlueSoft = Color(0xFFDBE1FF);
  static const answerBlueBorder = Color(0xFF001453);

  static const answerYellow = Color(0xFFA36700);
  static const answerYellowSoft = Color(0xFFFFF9C4);
  static const answerYellowBorder = Color(0xFF825100);

  static const answerGreen = Color(0xFF2E7D32);
  static const answerGreenSoft = Color(0xFFC8E6C9);
  static const answerGreenBorder = Color(0xFF1B5E20);

  static const answerRedSolid = Color(0xFFEF4444);
  static const answerBlueSolid = Color(0xFF2563EB);
  static const answerGreenSolid = Color(0xFF059669);
  static const answerAmberSolid = Color(0xFFF59E0B);

  // Aksen desain Create Quiz.
  static const quizAction = Color(0xFF6063EE);
  static const quizQuestionSurface = Color(0xFFE7EEFF);
  static const quizCoverSurface = Color(0xFFD8E3FB);
  static const quizCoverBorder = Color(0xFF767586);

  // Brand/gradient extras
  static const brandIndigo = Color(0xFF6063EE);

  // Shadows / overlays
  static const shadowBlack00 = Color(0x00000000);
  static const shadowBlack05 = Color(0x0C000000);
  static const shadowBlack06 = Color(0x0F000000);
  static const shadowBlack08 = Color(0x14000000);
  static const shadowBlack10 = Color(0x19000000);
  static const shadowBlack12 = Color(0x1F000000);
  static const shadowBlack20 = Color(0x33000000);
  static const shadowBlack40 = Color(0x66000000);
  static const shadowIndigo06 = Color(0x0F4B49D6);
  static const shadowIndigo08 = Color(0x144648D4);
  static const shadowIndigo14 = Color(0x244648D4);
  static const shadowIndigo18 = Color(0x2D4648D4);
  static const shadowIndigo20 = Color(0x334648D4);
  static const shadowViolet30 = Color(0x4C6B38D4);
}
