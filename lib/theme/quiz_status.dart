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
