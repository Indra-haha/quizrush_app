import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final bool elevated;
  final EdgeInsetsGeometry? padding;
  final double fontSize;
  final FontWeight fontWeight;

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
    this.elevated = false,
    this.padding,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w600,
  });

  /// Pill status room; warna titik diambil dari palet status yang sama dengan
  /// badge, sehingga `open` tidak pernah hijau di satu tempat dan oranye di tempat lain.
  factory AppPill.roomStatus(String status, {Key? key, bool elevated = true}) {
    return AppPill(
      key: key,
      text: QuizStatus.labelOf(status),
      background: Colors.white,
      foreground: AppColors.neutralDark,
      dot: QuizStatus.dotColor(status),
      elevated: elevated,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
        border: border == null ? null : Border.all(color: border!),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
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
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: foreground,
                fontSize: fontSize,
                fontWeight: fontWeight,
                height: 1.33,
              ),
            ),
          ),
          if (trailingText != null)
            Text(
              trailingText!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: trailingColor ?? foreground,
                fontSize: fontSize,
                fontWeight: fontWeight,
                height: 1.33,
              ),
            ),
        ],
      ),
    );
  }
}
