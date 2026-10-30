import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu statistik beranda: ikon dalam lingkaran, lalu label + nilai.
///
/// [highlight] memakai latar gradien brand dengan teks versi "aktif".
/// [largeValue] menampilkan nilai dengan ukuran 24pt (mis. jumlah host).
class HomeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final bool largeValue;
  final Color? iconBackground;
  final Color? iconColor;
  final VoidCallback? onTap;

  const HomeStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.largeValue = false,
    this.iconBackground,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = highlight
        ? AppTextStyles.homeStatLabelOnPrimary
        : AppTextStyles.labelSmall;
    final valueStyle = largeValue
        ? (highlight
              ? AppTextStyles.display2.copyWith(
                  color: AppColors.onPrimaryMuted,
                )
              : AppTextStyles.display2)
        : (highlight
              ? AppTextStyles.homeStatValueOnPrimary
              : AppTextStyles.homeStatValue);

    final card = Container(
      width: double.infinity,
      height: 128,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight ? null : AppColors.surface,
        gradient: highlight ? AppGradients.homeStatHighlight : null,
        borderRadius: AppRadius.xxl,
        border: highlight ? null : Border.all(color: AppColors.homeCardBorder),
        boxShadow: highlight ? null : AppShadows.hairlineTight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: AppSizes.homeStatIcon,
            height: AppSizes.homeStatIcon,
            decoration: BoxDecoration(
              color: highlight
                  ? AppColors.overlayLight
                  : (iconBackground ?? AppColors.homeTotalTint),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: AppIconSize.md,
              color: highlight
                  ? AppColors.textOnPrimary
                  : (iconColor ?? AppColors.textPrimary),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: labelStyle),
              const SizedBox(height: AppSpacing.space1),
              Text(value, style: valueStyle),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }
}
