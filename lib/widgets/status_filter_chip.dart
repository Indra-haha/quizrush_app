import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const StatusFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space7,
          vertical: AppSpacing.space3,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.textOnPrimary,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.divider,
          ),
          boxShadow: selected ? AppShadows.hairlineTight : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(
            color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
