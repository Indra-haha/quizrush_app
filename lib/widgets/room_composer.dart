import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Baris input pesan ruang tunggu beserta tombol kirim.
///
/// Menerima [enabled] dan [hintText] dari page; widget ini tidak tahu status
/// koneksi maupun cara mengirim.
class RoomComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hintText;
  final VoidCallback onSend;

  const RoomComposer({
    super.key,
    required this.controller,
    required this.enabled,
    required this.hintText,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space6,
        AppSpacing.space6,
        AppSpacing.space6,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: AppTextStyles.bodyMedium,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.info,
                ),
                filled: true,
                fillColor: AppColors.textOnPrimary,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space7,
                  vertical: AppSpacing.space6,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppRadius.lg,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.lg,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.lg,
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          IconButton.filled(
            tooltip: 'Kirim',
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send, size: AppIconSize.md),
          ),
        ],
      ),
    );
  }
}
