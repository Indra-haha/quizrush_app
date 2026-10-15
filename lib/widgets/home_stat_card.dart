import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu statistik beranda: ikon di atas, label + nilai di bawah.
///
/// [highlight] memakai dekorasi & teks versi "aktif" (latar brand).
class HomeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  const HomeStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 128,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: highlight
          ? AppDecorations.statTileActive
          : AppDecorations.statTile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            icon,
            size: AppIconSize.xl,
            color: highlight ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: highlight
                    ? AppTextStyles.statLabelOnPrimary
                    : AppTextStyles.bodyMeta,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                value,
                style: highlight
                    ? AppTextStyles.statValueOnPrimary
                    : AppTextStyles.statValue,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
