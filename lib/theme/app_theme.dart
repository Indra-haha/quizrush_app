import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Central design tokens.
///
/// Setiap widget dan halaman WAJIB membaca warna, tipografi, spacing,
/// radius, dan shadow dari file ini. Jangan menulis nilai warna,
/// font, atau spacing secara hardcoded di file lain.
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

class AppSpacing {
  AppSpacing._();

  // --- numeric scale (every value used anywhere in the app) ---
  static const none = 0.0;
  static const space1 = 2.0;
  static const space2 = 4.0;
  static const space3 = 6.0;
  static const space4 = 8.0;
  static const space5 = 10.0;
  static const space6 = 12.0;
  static const space7 = 14.0;
  static const space8 = 16.0;
  static const space9 = 20.0;
  static const space10 = 24.0;
  static const space11 = 28.0;
  static const space12 = 32.0;
  static const space13 = 40.0;
  static const space14 = 48.0;
  static const space15 = 15.0;
  static const space16 = 25.0;

  // --- clearances for floating UI / scroll views ---
  static const fabClearance = 96.0;
  static const scrollClearance = 112.0;
  static const scrollClearanceLarge = 160.0;

  // --- semantic aliases ---
  static const xxs = space2;
  static const xs = space4;
  static const sm = space6;
  static const md = space8;
  static const lg = space9;
  static const xl = space10;
  static const xxl = space12;
}

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

/// Icon glyph sizes.
class AppIconSize {
  AppIconSize._();

  static const micro = 12.0;
  static const xs = 14.0;
  static const body = 18.0;
  static const sm = 16.0;
  static const md = 20.0;
  static const lg = 24.0;
  static const xl = 28.0;
  static const xxl = 32.0;
  static const hero = 48.0;
  static const illustration = 56.0;
  static const display = 80.0;
}

/// Border stroke widths.
class AppBorderWidth {
  AppBorderWidth._();

  static const hairline = 1.0;
  static const thin = 1.5;
  static const regular = 2.0;
  static const thick = 3.0;
  static const heavy = 4.0;
}

class AppElevation {
  AppElevation._();

  static const none = 0.0;
  static const subtle = 2.0;
  static const medium = 3.0;
  static const raised = 8.0;
}

class AppRadius {
  AppRadius._();

  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const pill = BorderRadius.all(Radius.circular(999));
}

class AppShadows {
  AppShadows._();

  /// Standard content card.
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x19000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Raised / prominent surface.
  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Very tight 1px-style lift.
  static const hairlineTight = <BoxShadow>[
    BoxShadow(color: Color(0x0C000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Soft hairline.
  static const hairline = <BoxShadow>[
    BoxShadow(color: Color(0x0C000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Subtle shadow for tiles.
  static const subtle = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Downward-only offset, no blur (soft edge at the bottom).
  static const softLift = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 0, offset: Offset(0, 8)),
  ];

  /// Wide, diffuse lift used on main content blocks.
  static const hairlineWide = <BoxShadow>[
    BoxShadow(color: Color(0x0F000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Two-layer card shadow (near + far).
  static const layeredCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -1,
    ),
  ];

  /// Floating pill button (FAB).
  static const pillButton = <BoxShadow>[
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 10,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 25,
      offset: Offset(0, 20),
      spreadRadius: -5,
    ),
  ];

  /// Brand-tinted glow for hero cards.
  static const brandGlow = <BoxShadow>[
    BoxShadow(color: Color(0x144648D4), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Floating / overlay surface.
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Inset-feeling highlight.
  static const inset = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];
}

class AppTextStyles {
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

  AppTextStyles._();

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

class AppDecorations {
  AppDecorations._();

  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.lg,
    boxShadow: AppShadows.card,
  );

  static BoxDecoration get surfaceRounded =>
      BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.md);

  static BoxDecoration get surfaceSoftRounded =>
      BoxDecoration(color: AppColors.surfaceSoft, borderRadius: AppRadius.md);

  static BoxDecoration get statTile => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.xl,
    border: Border.all(color: AppColors.divider),
  );

  static BoxDecoration get statTileActive =>
      BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.xl);

  static BoxDecoration get pill => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.pill,
    border: Border.all(color: AppColors.divider),
  );

  static BoxDecoration get input => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.md,
    border: Border.all(color: AppColors.divider),
  );
}

class AppGradients {
  AppGradients._();

  static const diagonal = <Alignment>[Alignment.topLeft, Alignment.bottomRight];

  /// Hero card / card artwork gradient.
  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6063EE), Color(0xFF4648D4)],
  );

  /// Flat brand fill used by hero cards without artwork.
  static const solidHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4648D4), Color(0xFF4648D4)],
  );
}

class AppButtons {
  AppButtons._();

  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    minimumSize: const Size(0, 50),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    elevation: 2,
    textStyle: AppTextStyles.button,
  );

  static ButtonStyle get primaryLarge => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    minimumSize: const Size(double.infinity, 50),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    textStyle: AppTextStyles.button,
  );

  static ButtonStyle get primaryCompact => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
    textStyle: AppTextStyles.buttonSmall,
  );

  static ButtonStyle get outline => ElevatedButton.styleFrom(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    elevation: 0,
    side: const BorderSide(color: AppColors.divider),
  );

  static ButtonStyle get text => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.buttonSmall,
  );

  static ButtonStyle get destructive => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.textOnPrimary,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    textStyle: AppTextStyles.button,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
      primary: AppColors.primary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.textPrimary,
      onPrimary: AppColors.textOnPrimary,
      onError: AppColors.textOnPrimary,
      outline: AppColors.divider,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.divider,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(style: AppButtons.primary),
      textButtonTheme: TextButtonThemeData(style: AppButtons.text),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
