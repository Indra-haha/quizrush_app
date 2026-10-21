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

  // Surface kanvas untuk halaman daftar quiz (desain MyQuiz).
  static const quizCanvas = Color(0xFFFBF8FF);

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
}

class AppStatus {
  AppStatus._();

  static const danger = Color(0xFFBA1A1A);
  static const onLightAlpha = Color(0x3DFFFFFF);
}
