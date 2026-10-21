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

  /// Tombol aksi utama pada halaman gabung room (desain "Siap Main?").
  static const joinButton = LinearGradient(
    begin: Alignment(0.20, -0.92),
    end: Alignment(0.80, 1.92),
    colors: [Color(0xFF4648D4), Color(0xFF8455EF)],
  );

  /// Kotak logo pada hero halaman gabung room.
  static const logoTile = LinearGradient(
    begin: Alignment(0.00, 0.00),
    end: Alignment(1.00, 1.00),
    colors: [Color(0xFF4648D4), Color(0xFF6B38D4)],
  );
}
