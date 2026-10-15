import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/quiz_status.dart';

/// Pil berbentuk kapsul dengan warna dan radius yang seragam.
///
/// Menggantikan implementasi pill yang sebelumnya ditulis ulang di beberapa
/// halaman: pil status room, badge jumlah, dan badge room yang difokuskan.
class AppPill extends StatelessWidget {
  final String text;
  final String? trailingText;
  final Color? trailingColor;
  final Color background;
  final Color foreground;
  final Color? border;
  final Color? dot;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;

  const AppPill({
    super.key,
    required this.text,
    this.trailingText,
    this.trailingColor,
    required this.background,
    required this.foreground,
    this.border,
    this.dot,
    this.icon,
    this.padding,
  });

  /// Pill status room; warna titik diambil dari palet status yang sama dengan
  /// badge, sehingga `open` tidak pernah hijau di satu tempat dan oranye di tempat lain.
  factory AppPill.roomStatus(String status, {Key? key}) {
    return AppPill(
      key: key,
      text: QuizStatus.labelOf(status),
      background: AppColors.textOnPrimary,
      foreground: AppColors.textSecondary,
      dot: QuizStatus.dotColor(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space4,
          ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.md,
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot != null) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.space3),
          ],
          if (icon != null) ...[
            Icon(icon, size: AppIconSize.xs, color: foreground),
            const SizedBox(width: AppSpacing.space2),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.statLabelOnPrimary.copyWith(
                color: foreground,
              ),
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.statLabelOnPrimary.copyWith(
                color: trailingColor ?? foreground,
              ),
            ),
        ],
      ),
    );
  }
}
