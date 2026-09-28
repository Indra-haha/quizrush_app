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

  static ({Color fg, Color bg, Color border, Color dot}) palette(String status) {
    switch (status) {
      case 'waiting':
        return (
          fg: AppColors.inkStrong,
          bg: AppColors.softLavender,
          border: AppColors.softLavender,
          dot: AppColors.brandDeep,
        );
      case 'open':
        return (
          fg: AppColors.warningDark,
          bg: AppColors.warningBg,
          border: AppColors.warningBorder,
          dot: AppColors.warning,
        );
      case 'in-Game':
        return (
          fg: AppColors.successDark,
          bg: AppColors.successBg,
          border: AppColors.successBorder,
          dot: AppColors.success,
        );
      case 'ended':
        return (
          fg: AppColors.neutralDark,
          bg: AppColors.neutralBg,
          border: AppColors.neutralBorder,
          dot: AppColors.neutral,
        );
      case 'quarantine':
        return (
          fg: AppColors.badgePurple,
          bg: AppColors.softPurple,
          border: AppColors.softPurple,
          dot: AppColors.badgePurple,
        );
      default:
        return (
          fg: AppColors.inkStrong,
          bg: AppColors.softLavender,
          border: AppColors.softLavender,
          dot: AppColors.brandDeep,
        );
    }
  }

  static Color dotColor(String status) => palette(status).dot;
}
