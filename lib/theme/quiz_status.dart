import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Peta warna tunggal untuk semua status quiz dan room.
///
/// Halaman, badge, dan pil semuanya membaca dari sini supaya warna `open`
/// tidak pernah beda di dua tempat.
class QuizStatus {
  QuizStatus._();

  static const all = ['waiting', 'open', 'in-Game', 'ended', 'quarantine'];

  static String labelOf(String status) {
    if (status.isEmpty) return status;
    return '${status[0].toUpperCase()}${status.substring(1)}';
  }

  /// Label badge status mengikuti desain MyQuiz: LIVE, WAITING, SELESAI.
  /// [labelOf] tidak berubah supaya chip filter dan pil lama tetap sama.
  static String badgeLabelOf(String status) {
    switch (status) {
      case 'waiting':
        return 'WAITING';
      case 'open':
        return 'OPEN';
      case 'in-Game':
        return 'LIVE';
      case 'ended':
        return 'SELESAI';
      case 'quarantine':
        return 'QUARANTINE';
      default:
        return labelOf(status).toUpperCase();
    }
  }

  /// Warna badge status mengikuti desain MyQuiz: LIVE merah, WAITING amber,
  /// SELESAI indigo tipis. [palette] lama tidak berubah.
  static ({Color fg, Color bg, Color dot}) badgePalette(String status) {
    switch (status) {
      case 'waiting':
        return (
          fg: AppColors.amberInk,
          bg: AppColors.amberSoft,
          dot: AppColors.amberInk,
        );
      case 'open':
        return (
          fg: AppColors.warning,
          bg: AppColors.surfaceSoft,
          dot: AppColors.warning,
        );
      case 'in-Game':
        return (
          fg: AppColors.error,
          bg: AppColors.errorSoft,
          dot: AppColors.error,
        );
      case 'ended':
        return (
          fg: AppColors.endedInk,
          bg: AppColors.endedTint,
          dot: AppColors.endedInk,
        );
      default:
        return (
          fg: AppColors.textPrimary,
          bg: AppColors.primarySoft,
          dot: AppColors.primaryDark,
        );
    }
  }

  static ({Color fg, Color bg, Color border, Color dot}) palette(
    String status,
  ) {
    switch (status) {
      case 'waiting':
        return (
          fg: AppColors.textPrimary,
          bg: AppColors.primarySoft,
          border: AppColors.primarySoft,
          dot: AppColors.primaryDark,
        );
      case 'open':
        return (
          fg: AppColors.warning,
          bg: AppColors.surfaceSoft,
          border: AppColors.warning,
          dot: AppColors.warning,
        );
      case 'in-Game':
        return (
          fg: AppColors.success,
          bg: AppColors.surfaceSoft,
          border: AppColors.success,
          dot: AppColors.success,
        );
      case 'ended':
        return (
          fg: AppColors.textSecondary,
          bg: AppColors.surfaceSoft,
          border: AppColors.divider,
          dot: AppColors.info,
        );
      case 'quarantine':
        return (
          fg: AppColors.primary,
          bg: AppColors.primarySoft,
          border: AppColors.primarySoft,
          dot: AppColors.primary,
        );
      default:
        return (
          fg: AppColors.textPrimary,
          bg: AppColors.primarySoft,
          border: AppColors.primarySoft,
          dot: AppColors.primaryDark,
        );
    }
  }

  static Color dotColor(String status) => palette(status).dot;
}
