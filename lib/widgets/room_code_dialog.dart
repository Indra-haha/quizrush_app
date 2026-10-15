import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';
import 'app_snackbar.dart';

/// Dialog yang menampilkan kode room yang baru dibuat beserta tombol salin.
Future<void> showRoomCodeDialog(BuildContext context, String kode) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Room Dibuat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Kode Room',
            style: AppTextStyles.statLabelOnPrimary.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(kode, style: AppTextStyles.code),
          const SizedBox(height: AppSpacing.space8),
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: kode));
              AppSnackBar.show(
                dialogContext,
                'Kode room disalin.',
                duration: const Duration(seconds: 1),
              );
            },
            icon: const Icon(Icons.copy, size: AppIconSize.sm),
            label: const Text('Salin'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
