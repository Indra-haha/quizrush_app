import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Bar status koneksi ruang tunggu: titik warna, label, jumlah pemain, dan
/// tombol coba lagi opsional.
///
/// Menerima primitif (warna, label, jumlah) supaya `widgets/` tidak bergantung
/// pada enum status di `services/`.
class RoomConnectionBar extends StatelessWidget {
  final Color statusColor;
  final String statusLabel;
  final int users;
  final VoidCallback? onRetry;

  const RoomConnectionBar({
    super.key,
    required this.statusColor,
    required this.statusLabel,
    required this.users,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space5,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.hairlineWide,
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Text(
              statusLabel,
              maxLines: 1,
              style: AppTextStyles.bodyMeta,
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          const Icon(
            Icons.group_outlined,
            size: AppIconSize.sm,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Text('$users Pemain', style: AppTextStyles.metricStrong),
          if (onRetry != null) ...[
            const SizedBox(width: AppSpacing.space4),
            _retryButton(),
          ],
        ],
      ),
    );
  }

  Widget _retryButton() {
    return SizedBox(
      height: 34,
      child: FilledButton(
        onPressed: onRetry,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
          textStyle: AppTextStyles.labelStrongSmallOnPrimary,
        ),
        child: const Text('Coba lagi'),
      ),
    );
  }
}
