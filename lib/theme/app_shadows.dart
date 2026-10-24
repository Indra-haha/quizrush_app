import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shadow presets. Setiap widget dan halaman WAJIB membaca shadow dari sini.
class AppShadows {
  AppShadows._();

  /// Standard content card.
  static const card = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack10, blurRadius: 8, offset: Offset(0, 2)),
  ];

  /// Raised / prominent surface.
  static const raised = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack08, blurRadius: 16, offset: Offset(0, 4)),
  ];

  /// Very tight 1px-style lift.
  static const hairlineTight = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack05, blurRadius: 2, offset: Offset(0, 1)),
  ];

  /// Soft hairline.
  static const hairline = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack05, blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Subtle shadow for tiles.
  static const subtle = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack06, blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// Downward-only offset, no blur (soft edge at the bottom).
  static const softLift = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack06, blurRadius: 0, offset: Offset(0, 8)),
  ];

  /// Wide, diffuse lift used on main content blocks.
  static const hairlineWide = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack06, blurRadius: 20, offset: Offset(0, 8)),
  ];

  /// Two-layer card shadow (near + far).
  static const layeredCard = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBlack10,
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
    BoxShadow(
      color: AppColors.shadowBlack10,
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -1,
    ),
  ];

  /// Kartu quiz berkelompok (desain MyQuiz): glow indigo lembut.
  static const quizCard = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowIndigo06,
      blurRadius: 18,
      offset: Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  /// Floating pill button (FAB).
  static const pillButton = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBlack10,
      blurRadius: 10,
      offset: Offset(0, 8),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: AppColors.shadowBlack10,
      blurRadius: 25,
      offset: Offset(0, 20),
      spreadRadius: -5,
    ),
  ];

  /// Brand-tinted glow for hero cards.
  static const brandGlow = <BoxShadow>[
    BoxShadow(color: AppColors.shadowIndigo08, blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// Kartu permukaan tinggi dengan dua lapis bayangan (desain halaman
  /// menunggu).
  static const softCard = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBlack10,
      blurRadius: 6,
      offset: Offset(0, 4),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: AppColors.shadowBlack10,
      blurRadius: 15,
      offset: Offset(0, 10),
      spreadRadius: -3,
    ),
  ];

  /// Floating / overlay surface.
  static const floating = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack20, blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// Navigasi bawah: garis tipis tepat di bawah bidang nav.
  static const navBar = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBlack20,
      blurRadius: 2,
      offset: Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  /// Kartu kuis beranda (desain baru): glow indigo dengan offset bawah.
  static const homeQuizCard = <BoxShadow>[
    BoxShadow(color: AppColors.shadowIndigo20, blurRadius: 0, offset: Offset(0, 8)),
  ];

  /// Tombol aksi beranda (desain baru).
  static const action = <BoxShadow>[
    BoxShadow(color: AppColors.shadowIndigo20, blurRadius: 0, offset: Offset(0, 4)),
  ];

  /// Kartu putih halaman auth (desain register baru).
  static const authCard = <BoxShadow>[
    BoxShadow(color: AppColors.shadowBlack20, blurRadius: 40, offset: Offset(0, 12)),
  ];

  /// Inset-feeling highlight.
  static const inset = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBlack06,
      blurRadius: 4,
      offset: Offset(0, 2),
      spreadRadius: -2,
    ),
  ];

  /// Glow indigo di belakang avatar profil.
  static const avatarGlow = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowIndigo18,
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
  ];

  /// Bayangan navigasi bawah yang jatuh ke atas (desain profil).
  static const navBarUp = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowBlack05,
      blurRadius: 12,
      offset: Offset(0, -2),
    ),
  ];
}
