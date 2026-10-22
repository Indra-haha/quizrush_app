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

  /// Panel gradien di atas halaman register (desain baru).
  static const authHero = LinearGradient(
    begin: Alignment(0.14, -0.14),
    end: Alignment(0.86, 1.14),
    colors: [Color(0xFF4648D4), Color(0xFF6B38D4)],
  );

  /// Gradien tombol aksi halaman auth (horizontal).
  static const authAction = LinearGradient(
    begin: Alignment(0, 0.5),
    end: Alignment(1, 0.5),
    colors: [Color(0xFF4648D4), Color(0xFF6B38D4)],
  );
}
