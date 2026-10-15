import 'package:flutter/material.dart';

/// Gradient presets. Setiap widget dan halaman WAJIB membaca gradient dari sini.
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
