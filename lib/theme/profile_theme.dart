import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_metrics.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';

/// Gaya khusus halaman profil.
class ProfileTheme {
  ProfileTheme._();

  static const headerElevation = AppElevation.hairline;

  static const contentPadding = EdgeInsets.fromLTRB(
    AppSpacing.space9,
    AppSpacing.space8,
    AppSpacing.space9,
    AppSpacing.scrollClearance,
  );

  static const sectionGap = AppSpacing.space8;

  static const cardDecoration = BoxDecoration(
    color: AppColors.pureSurface,
    borderRadius: AppRadius.xxl,
    boxShadow: AppShadows.navBar,
  );

  static const heroPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space10,
    vertical: AppSpacing.space10,
  );

  static const paddingSmall = EdgeInsets.all(AppSpacing.space2);

  static const avatarDecoration = BoxDecoration(
    color: AppColors.surfaceSoft,
    shape: BoxShape.circle,
    boxShadow: AppShadows.avatarGlow,
  );

  static const avatarBackground = AppColors.surfaceSoft;

  static const nameWidth = 188.0;

  static const gapMedium = AppSpacing.space6;
  static const gapTiny = AppSpacing.space1;

  static const pillPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space6,
    vertical: AppSpacing.space2,
  );

  static const pillDecoration = ShapeDecoration(
    color: AppColors.primarySoft,
    shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
  );

  static const statsPadding = EdgeInsets.all(AppSpacing.space8);

  static const statTilePadding = EdgeInsets.symmetric(
    vertical: AppSpacing.space2,
  );

  static const settingsPadding = EdgeInsets.all(AppSpacing.space6);

  static const settingRowPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space5,
    vertical: AppSpacing.space6,
  );
  static const iconLarge = AppIconSize.lg;
  static const iconMedium = AppIconSize.md;
  static const settingIconColor = AppColors.primary;
  static const settingTrailingGap = AppSpacing.space4;
  static const chevronColor = AppColors.textSecondary;
  static const toggleDuration = Duration(milliseconds: 180);
  static const toggleCurve = Curves.easeOut;
  static const toggleActiveAlignment = Alignment.centerRight;
  static const toggleInactiveAlignment = Alignment.centerLeft;
  static const toggleEnabledOpacity = 1.0;
  static const toggleDisabledOpacity = 0.5;
  static const toggleKnobDecoration = ShapeDecoration(
    color: AppColors.pureSurface,
    shape: CircleBorder(),
    shadows: AppShadows.hairlineTight,
  );

  static BoxDecoration toggleDecoration({required bool active}) {
    return BoxDecoration(
      gradient: active ? AppGradients.toggleActive : null,
      color: active ? null : AppColors.primaryBorder,
      borderRadius: AppRadius.pill,
    );
  }

  static const logoutColor = AppColors.error;
  static const logoutProgressStroke = AppBorderWidth.regular;
}
