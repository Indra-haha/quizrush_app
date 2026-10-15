import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_metrics.dart';
import 'app_shadows.dart';

class AppDecorations {
  AppDecorations._();

  static BoxDecoration get card => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.lg,
    boxShadow: AppShadows.card,
  );

  static BoxDecoration get surfaceRounded =>
      BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.md);

  static BoxDecoration get surfaceSoftRounded =>
      BoxDecoration(color: AppColors.surfaceSoft, borderRadius: AppRadius.md);

  static BoxDecoration get statTile => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.xl,
    border: Border.all(color: AppColors.divider),
  );

  static BoxDecoration get statTileActive =>
      BoxDecoration(color: AppColors.primary, borderRadius: AppRadius.xl);

  static BoxDecoration get pill => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.pill,
    border: Border.all(color: AppColors.divider),
  );

  static BoxDecoration get input => BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.md,
    border: Border.all(color: AppColors.divider),
  );
}
