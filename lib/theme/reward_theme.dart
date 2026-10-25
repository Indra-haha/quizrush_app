import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_gradients.dart';
import 'app_metrics.dart';
import 'app_shadows.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

/// Layout, dekorasi, dan gaya teks bagian poin halaman Reward.
class RewardTheme {
  RewardTheme._();

  static const pagePadding = EdgeInsets.fromLTRB(
    AppSpacing.space8,
    AppSpacing.space8,
    AppSpacing.space8,
    AppSpacing.space12,
  );
  static const sectionGap = AppSpacing.space8;
  static const contentGap = AppSpacing.space6;

  static const heroPadding = EdgeInsets.all(AppSpacing.space10);
  static const heroRadius = AppRadius.lg;
  static const heroShadow = AppShadows.rewardCard;
  static const heroOrbSize = 144.0;
  static const heroOrbOverlap = -32.0;
  static const heroOrbColor = AppColors.onPrimaryWash;

  static const equivalentBadgePadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space5,
    vertical: AppSpacing.space2,
  );
  static const equivalentBadgeRadius = BorderRadius.all(Radius.circular(32));
  static const equivalentBadgeColor = AppColors.onPrimaryVeil;

  static const cardPadding = EdgeInsets.all(AppSpacing.space8);
  static const cardRadius = AppRadius.lg;
  static const cardShadow = AppShadows.rewardCard;

  static const iconCircleSize = 40.0;
  static const iconSize = AppIconSize.md;
  static const actionGap = AppSpacing.space8;

  static const actionRadius = BorderRadius.all(Radius.circular(6));
  static const actionPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space8,
    vertical: AppSpacing.space6,
  );
  static const actionDecoration = BoxDecoration(
    gradient: AppGradients.action,
    borderRadius: actionRadius,
    boxShadow: AppShadows.rewardAction,
  );

  static const historyCardPadding = EdgeInsets.all(AppSpacing.space8);
  static const historyCardRadius = AppRadius.rewardHistory;
  static const historyCardShadow = AppShadows.rewardHistory;
  static const historyTitleGap = AppSpacing.space6;
  static const historyItemGap = AppSpacing.space4;

  static Color historyIconBackground(int amount) =>
      amount >= 0 ? AppColors.heroPeach : AppColors.participantTile;

  static Color historyIconColor(int amount) =>
      amount >= 0 ? AppColors.rewardAmountInk : AppColors.primary;

  static IconData historyIcon(String reason, int amount) {
    if (reason == 'quiz_reward') return Icons.emoji_events_rounded;
    if (amount < 0) return Icons.swap_horiz_rounded;
    return Icons.toll_rounded;
  }
}

/// Gaya teks bagian poin halaman Reward.
class RewardTextStyles {
  RewardTextStyles._();

  static final heroLabel = AppTextStyles.heading5.copyWith(
    color: AppColors.textOnPrimary,
    height: 1,
    letterSpacing: 0.6,
  );

  static final heroValue = AppTextStyles.display1.copyWith(
    color: AppColors.textOnPrimary,
    fontSize: 32,
    height: 1.5,
    letterSpacing: -1,
  );

  static final heroUnit = AppTextStyles.display2.copyWith(
    color: AppColors.textOnPrimary,
    fontWeight: AppFontWeight.bold,
    height: 1.33,
  );

  static final heroEquivalent = AppTextStyles.labelStrong.copyWith(
    color: AppColors.textOnPrimary,
    fontWeight: AppFontWeight.semibold,
    height: 1.14,
  );

  static final cardTitle = AppTextStyles.heading5.copyWith(
    color: AppColors.textPrimary,
    height: 1.75,
  );

  static final cardBody = AppTextStyles.bodySmall.copyWith(
    color: AppColors.textSecondary,
    fontWeight: AppFontWeight.medium,
    height: 1.63,
  );

  static final actionLabel = AppTextStyles.button.copyWith(
    color: AppColors.onPrimaryMuted,
    fontFamily: AppTextStyles.display1.fontFamily,
    fontWeight: AppFontWeight.bold,
    height: 1.5,
  );

  static final historyTitle = AppTextStyles.heading3.copyWith(
    color: AppColors.textPrimary,
    height: 1.56,
  );

  static final historyItemTitle = AppTextStyles.labelStrong.copyWith(
    color: AppColors.textPrimary,
    fontFamily: AppTextStyles.display1.fontFamily,
    height: 1.43,
  );

  static final historyItemMeta = AppTextStyles.bodySmall.copyWith(
    color: AppColors.textSecondary,
    fontWeight: AppFontWeight.regular,
    height: 1.33,
  );

  static final historyAmount = AppTextStyles.labelStrong.copyWith(
    color: AppColors.rewardAmountInk,
    fontFamily: AppTextStyles.display1.fontFamily,
    height: 1.43,
  );

  static final historyEmpty = AppTextStyles.bodySmall.copyWith(
    color: AppColors.textSecondary,
  );
}
