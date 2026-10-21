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

  static const xs = BorderRadius.all(Radius.circular(6));
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const xxl = BorderRadius.all(Radius.circular(32));
  static const pill = BorderRadius.all(Radius.circular(999));
}
