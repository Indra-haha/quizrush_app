import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol "muat lebih banyak" bergaya kartu untuk menampilkan sisa item.
class LoadMoreButton extends StatelessWidget {
  final int remaining;
  final int total;
  final VoidCallback onTap;

  const LoadMoreButton({
    super.key,
    required this.remaining,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space10,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            boxShadow: AppShadows.hairlineTight,
          ),
          child: Text(
            'Muat $remaining Soal Lainnya (Total $total Soal)',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
