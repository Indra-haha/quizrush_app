import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kotak statistik yang dipakai hero card quiz dan detail room.
///
/// Dua halaman punya bentuk yang berbeda (bertumpuk di atas surface gelap, atau
/// baris dengan ikon di kiri), tapi token tipografi dan shadow-nya sama, jadi
/// keduanya lewat widget ini dengan named constructor yang berbeda.
class AppStatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconBackground;
  final Color? background;
  final Color? foreground;
  final Color? borderColor;
  final double fontSize;
  final bool onDarkSurface;
  final bool compact;

  const AppStatTile.stacked({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.onDarkSurface = true,
  }) : iconBackground = null,
       background = null,
       foreground = null,
       borderColor = null,
       fontSize = 16,
       compact = false;

  const AppStatTile.detailed({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required Color iconBg,
  }) : onDarkSurface = false,
       iconBackground = iconBg,
       background = null,
       foreground = null,
       borderColor = null,
       fontSize = 16,
       compact = false;

  /// Kotak nilai kecil bergaya netral atau hangat, tanpa label bawah dan tanpa
  /// ikon, dipakai pada header halaman test quiz ("Max 20 pts", total skor).
  const AppStatTile.compact({
    super.key,
    required this.value,
    required Color bg,
    required Color fg,
    this.fontSize = 16,
    this.borderColor,
  }) : icon = Icons.abc,
       label = '',
       iconBackground = null,
       background = bg,
       foreground = fg,
       onDarkSurface = false,
       compact = true;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.sm,
          border: borderColor == null ? null : Border.all(color: borderColor!),
          boxShadow: AppShadows.hairlineTight,
        ),
        child: Center(
          child: Text(
            value,
            style: AppTextStyles.display1.copyWith(color: foreground),
          ),
        ),
      );
    }

    return Container(
      padding: onDarkSurface
          ? const EdgeInsets.symmetric(
              vertical: AppSpacing.space6,
              horizontal: AppSpacing.space4,
            )
          : const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: onDarkSurface
            ? AppColors.textOnPrimary.withValues(alpha: 0.16)
            : AppColors.textOnPrimary,
        borderRadius: onDarkSurface ? AppRadius.lg : null,
        boxShadow: onDarkSurface ? null : AppShadows.hairlineTight,
      ),
      child: onDarkSurface ? _buildStacked() : _buildDetailed(),
    );
  }

  Widget _buildStacked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.textOnPrimary, size: AppIconSize.body),
        const SizedBox(height: AppSpacing.space3),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.heading5.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.space1),
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyCaption.copyWith(
            color: AppColors.textOnPrimary.withValues(alpha: 0.80),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailed() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBackground,
            borderRadius: AppRadius.sm,
          ),
          child: Icon(icon, size: AppIconSize.md, color: AppColors.textPrimary),
        ),
        const SizedBox(width: AppSpacing.space6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: AppTextStyles.heading3),
            Text(label, style: AppTextStyles.bodyMeta),
          ],
        ),
      ],
    );
  }
}
