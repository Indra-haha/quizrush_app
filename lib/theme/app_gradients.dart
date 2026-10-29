import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Gradient presets. Setiap widget dan halaman WAJIB membaca gradient dari sini.
class AppGradients {
  AppGradients._();

  /// Hero card / card artwork gradient.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.quizAction, AppColors.primary],
  );

  /// Flat brand fill used by hero cards without artwork.
  static const solidHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.primary],
  );

  /// Panel gradien di atas halaman register (desain baru).
  static const authHero = LinearGradient(
    begin: Alignment(0.14, -0.14),
    end: Alignment(0.86, 1.14),
    colors: [AppColors.primary, AppColors.gradientEnd],
  );

  /// Kartu statistik unggulan beranda (desain baru).
  static const homeStatHighlight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.primary, AppColors.quizAction],
  );

  /// Gradien tombol aksi beranda (horizontal).
  static const action = LinearGradient(
    begin: Alignment(0, 0.5),
    end: Alignment(1, 0.5),
    colors: [AppColors.primary, AppColors.gradientEnd],
  );

  /// Kartu total poin halaman Reward (desain poin).
  static const rewardHero = LinearGradient(
    begin: Alignment(0.31, -0.31),
    end: Alignment(0.69, 1.31),
    colors: [AppColors.primary, AppColors.quizAction, AppColors.gradientEnd],
  );

  /// Track toggle aktif pada kartu pengaturan profil (vertikal).
  static const toggleActive = LinearGradient(
    begin: Alignment(0.5, -0.0),
    end: Alignment(0.5, 1.0),
    colors: [AppColors.primary, AppColors.gradientEnd],
  );

  /// Gradien medali emas (peringkat 1).
  static const medalGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.medalGoldStart, AppColors.medalGoldEnd],
  );

  /// Gradien medali perak (peringkat 2).
  static const medalSilver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.medalSilverStart, AppColors.medalSilverEnd],
  );

  /// Gradien medali perunggu (peringkat 3).
  static const medalBronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.medalBronzeStart, AppColors.medalBronzeEnd],
  );
}
