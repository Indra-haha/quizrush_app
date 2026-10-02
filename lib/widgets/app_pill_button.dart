import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showProgress;

  const AppPillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSpacing.space14,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: AppRadius.md,
          boxShadow: AppShadows.pillButton,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.md,
            onTap: showProgress ? null : onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showProgress)
                    const SizedBox(
                      width: AppSpacing.space9,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  else if (icon != null) ...[
                    Icon(
                      icon,
                      size: AppIconSize.sm,
                      color: AppColors.textOnPrimary,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                  ],
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.background,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
