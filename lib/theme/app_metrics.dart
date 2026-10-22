import 'package:flutter/material.dart';

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
  static const xxl = BorderRadius.all(Radius.circular(32));
  static const pill = BorderRadius.all(Radius.circular(999));

  /// Panel hero halaman auth: sudut bawah membulat.
  static const authHero = BorderRadius.only(
    bottomLeft: Radius.circular(32),
    bottomRight: Radius.circular(32),
  );

  /// Kartu form auth: sudut atas lebih besar dari sudut bawah.
  static const authCard = BorderRadius.only(
    topLeft: Radius.circular(36),
    topRight: Radius.circular(36),
    bottomLeft: Radius.circular(28),
    bottomRight: Radius.circular(28),
  );

  /// Tombol aksi berbentuk kapsul.
  static const authAction = BorderRadius.all(Radius.circular(48));

  /// Kotak centang syarat & ketentuan.
  static const checkbox = BorderRadius.all(Radius.circular(2.5));
}

/// Fixed component sizes that are neither spacing nor icon glyphs.
class AppSizes {
  AppSizes._();

  /// Circular back button on the waiting room hero.
  static const backButton = 36.0;

  /// Avatar circle of a participant tile.
  static const avatar = 56.0;

  /// Placeholder circle of an empty participant slot.
  static const emptySlot = 64.0;

  /// Status dot of the waiting room summary card.
  static const statusDot = 16.0;

  /// Maximum width of the glass card inside the waiting room hero.
  static const heroCard = 350.0;

  /// Tinggi panel gradien di atas halaman register.
  static const authHero = 242.0;

  /// Jarak wordmark dari tepi atas panel hero halaman register.
  static const authHeroTop = 70.0;

  /// Tinggi minimum halaman register.
  static const authPageMinHeight = 780.0;

  /// Sisi kotak centang syarat & ketentuan.
  static const termsCheckbox = 13.0;

  /// Diameter tombol bulat biometrik pada halaman login.
  static const authBiometric = 64.0;
}
