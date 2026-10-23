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

  /// Kartu permukaan tinggi dengan dua lapis bayangan (desain halaman
  /// menunggu).
  static const softCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0x19000000),
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];

  /// Floating / overlay surface.
  static const floating = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Navigasi bawah: garis tipis tepat di bawah bidang nav.
  static const navBar = <BoxShadow>[
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Kartu kuis beranda (desain baru): glow indigo dengan offset bawah.
  static const homeQuizCard = <BoxShadow>[
    BoxShadow(color: Color(0x334648D4), blurRadius: 0, offset: Offset(0, 8)),
  ];

  /// Tombol aksi beranda (desain baru).
  static const action = <BoxShadow>[
    BoxShadow(color: Color(0x334648D4), blurRadius: 0, offset: Offset(0, 4)),
  ];

  /// Kartu putih halaman auth (desain register baru).
  static const authCard = <BoxShadow>[
    BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, 12)),
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

  /// Glow indigo di belakang avatar profil.
  static const avatarGlow = <BoxShadow>[
    BoxShadow(
      color: Color(0x2D4648D4),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Bayangan navigasi bawah yang jatuh ke atas (desain profil).
  static const navBarUp = <BoxShadow>[
    BoxShadow(
      color: Color(0x0C000000),
      blurRadius: 12,
      offset: Offset(0, -2),
    ),
  ];
}
