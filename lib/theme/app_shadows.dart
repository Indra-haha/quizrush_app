import 'package:flutter/material.dart';

/// Shadow presets. Setiap widget dan halaman WAJIB membaca shadow dari sini.
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

  /// Kartu quiz berkelompok (desain MyQuiz): glow indigo lembut.
  static const quizCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x0F4B49D6),
      blurRadius: 18,
      offset: Offset(0, 4),
      spreadRadius: -2,
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

  /// Kartu utama halaman gabung room: bayangan lebar lembut di bawah kartu.
  static const joinCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 40,
      offset: Offset(0, 12),
      spreadRadius: 0,
    ),
  ];
}
