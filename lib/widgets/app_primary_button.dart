import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol aksi utama yang tampil di halaman detail: Publish, Masuk, dan
/// aksi create. Menyatukan `FilledButton.styleFrom` yang sebelumnya ditulis
/// inline di setiap halaman.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double radius;
  final EdgeInsetsGeometry padding;
  final String? loadingLabel;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.radius = 14,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.space9,
      vertical: AppSpacing.space7,
    ),
    this.loadingLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.divider,
        disabledForegroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: padding,
      ),
      child: loading
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                if (loadingLabel != null) ...[
                  const SizedBox(width: AppSpacing.space5),
                  Text(loadingLabel!, style: _labelStyle),
                ],
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.body),
                  const SizedBox(width: AppSpacing.space4),
                ],
                Text(label, style: _labelStyle),
              ],
            ),
    );
  }

  TextStyle get _labelStyle =>
      AppTextStyles.labelStrong.copyWith(color: AppColors.textOnPrimary);
}
