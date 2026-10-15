import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu pengantar pada halaman input PIN room.
class EnterPinIntroCard extends StatelessWidget {
  const EnterPinIntroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space9),
      decoration: BoxDecoration(
        gradient: AppGradients.solidHero,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.brandGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.16),
              borderRadius: AppRadius.md,
            ),
            child: const Icon(
              Icons.pin_outlined,
              color: AppColors.textOnPrimary,
              size: AppIconSize.lg,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'Gabung ke Room',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Masukkan 6 digit PIN room untuk memverifikasi lalu '
            'masuk ke ruang tunggu kuis.',
            style: AppTextStyles.bodyMediumOnPrimary.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}
