import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const primary = Color(0xFF4648D4);
  static const brandDeep = Color(0xFF4F46E5);
  static const highlight = Color(0xFF6063EE);
  static const ink = Color(0xFF111C2D);
  static const muted = Color(0xFF464554);
  static const cardBg = Color(0xFFF9F9FF);
  static const softBg = Color(0xFFDEE8FF);
  static const border = Color(0xFFC7C4D7);
  static const onHighlight = Color(0xFFFFFBFF);
  static const background = Color(0xFFF0EFFF);
  static const lineLight = Color(0xFFF1F5F9);

  static const inkStrong = Color(0xFF07006C);
  static const accentPurple = Color(0xFF6B38D4);
  static const badgePurple = Color(0xFF8455EF);
  static const ptsInk = Color(0xFF825100);

  static const softLavender = Color(0xFFE1E0FF);
  static const softPurple = Color(0xFFE9DDFF);
  static const heroBg = Color(0xFFE7EEFF);
  static const optionBg = Color(0xFFF0F3FF);
  static const warmSurface = Color(0xFFFFDDB8);

  static const borderSoft = Color(0x4CC7C4D7);

  static const borderSlate = Color(0xFFCBD5E1);
  static const formFieldBg = Color(0xFFF0F3FF);
  static const placeholder = Color(0xFF6B7280);
  static const placeholderMuted = Color(0xFF767586);
  static const dangerAction = Color(0xFFBA1A1A);
  static const warmInk = Color(0xFF2A1700);

  static const successSoft = Color(0xFFC8E6C9);
  static const successInk = Color(0xFF1B5E20);
  static const dangerSoft = Color(0xFFFFDAD6);
  static const dangerInk = Color(0xFF93000A);

  static const shadowSoft = Color(0x0C000000);
  static const shadowCard = Color(0x19000000);
  static const shadowHairline = Color(0x0F000000);
  static const shadowBrand = Color(0x144648D4);

  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF059669);
  static const successBg = Color(0xFFECFDF5);
  static const successBorder = Color(0xFFA7F3D0);

  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFD97706);
  static const warningBg = Color(0xFFFFFBEB);
  static const warningBorder = Color(0xFFFDE68A);

  static const neutral = Color(0xFF94A3B8);
  static const neutralDark = Color(0xFF475569);
  static const neutralBg = Color(0xFFF1F5F9);
  static const neutralBorder = Color(0xFFE2E8F0);
}

class AppTextStyles {
  AppTextStyles._();

  static final heading1 = GoogleFonts.montserrat(
    color: AppColors.ink,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.21,
  );

  static final heading2 = GoogleFonts.montserrat(
    color: AppColors.ink,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 1.56,
  );

  static final bodyMeta = GoogleFonts.plusJakartaSans(
    color: AppColors.muted,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static final bodyCaption = GoogleFonts.plusJakartaSans(
    color: AppColors.muted,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.50,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
    ).copyWith(primary: AppColors.primary, surface: AppColors.cardBg);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.cardBg,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: AppTextStyles.heading1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
