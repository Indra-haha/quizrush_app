import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_pill.dart';

/// Header seksi "Daftar Room" dengan jumlah room pada halaman detail kuis.
class RoomListHeader extends StatelessWidget {
  final int count;

  const RoomListHeader({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Daftar Room', style: AppTextStyles.display2),
            const SizedBox(width: AppSpacing.space4),
            AppPill(
              text: '$count Room',
              background: AppColors.primarySoft,
              foreground: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Pilih room untuk langsung bergabung ke server kuis',
          style: AppTextStyles.bodyMeta,
        ),
      ],
    );
  }
}
