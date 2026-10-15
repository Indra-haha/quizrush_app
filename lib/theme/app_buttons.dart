import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_metrics.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

class AppButtons {
  AppButtons._();

  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    minimumSize: const Size(0, 50),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    elevation: 2,
    textStyle: AppTextStyles.button,
  );

  static ButtonStyle get primaryLarge => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    minimumSize: const Size(double.infinity, 50),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    textStyle: AppTextStyles.button,
  );

  static ButtonStyle get primaryCompact => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.pill),
    textStyle: AppTextStyles.buttonSmall,
  );

  static ButtonStyle get outline => ElevatedButton.styleFrom(
    backgroundColor: AppColors.surface,
    foregroundColor: AppColors.textPrimary,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    elevation: 0,
    side: const BorderSide(color: AppColors.divider),
  );

  static ButtonStyle get text => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.buttonSmall,
  );

  static ButtonStyle get destructive => ElevatedButton.styleFrom(
    backgroundColor: AppColors.error,
    foregroundColor: AppColors.textOnPrimary,
    shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
    textStyle: AppTextStyles.button,
  );
}
