import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Search field untuk halaman quiz (cari judul atau PIN).
class QuizSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRefresh;
  final bool syncing;
  final bool loading;

  const QuizSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onRefresh,
    required this.syncing,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ketik judul kuis atau 6 digit PIN...',
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
        filled: true,
        fillColor: AppColors.textOnPrimary.withValues(alpha: 0.70),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space8,
          vertical: AppSpacing.space6,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: AppIconSize.sm,
          color: AppColors.info,
        ),
        suffixIcon: syncing
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.space7),
                child: SizedBox(
                  width: AppSpacing.space7,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
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
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }
}
