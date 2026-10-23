import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tampilan error dengan aksi coba lagi.
///
/// `buttonColor` dan `messageStyle` dihapus supaya halaman tidak menyuntik
/// style; warna tombol dan tipografi sekarang satu keputusan widget ini.
class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorStateView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: AppIconSize.hero,
            color: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.space6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space10),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.space8),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }
}
