import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tombol aksi sekunder: outline tebal dengan label brand, dipakai untuk
/// "Tambah Pertanyaan" di halaman create quiz.
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;
  final double radius;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.iconSize = 48,
    this.radius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        side: const BorderSide(
          color: AppColors.divider,
          width: AppBorderWidth.heavy,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space9,
          vertical: AppSpacing.space8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textOnPrimary),
          ),
          const SizedBox(width: AppSpacing.space6),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppTextStyles.display2.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
