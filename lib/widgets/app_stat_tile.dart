import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: borderColor == null
              ? null
              : Border.all(color: borderColor!),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadowSoft,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Center(
          child: Text(
            value,
            style: GoogleFonts.montserrat(
              color: foreground,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: onDarkSurface
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 8)
          : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onDarkSurface
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white,
        borderRadius: onDarkSurface ? BorderRadius.circular(16) : null,
        boxShadow: onDarkSurface
            ? null
            : const [
                BoxShadow(
                  color: AppColors.shadowSoft,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
      ),
      child: onDarkSurface ? _buildStacked() : _buildDetailed(),
    );
  }

  Widget _buildStacked() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.montserrat(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.20,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.80),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.33,
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
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.ink),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.33,
              ),
            ),
            Text(label, style: AppTextStyles.bodyMeta),
          ],
        ),
      ],
    );
  }
}
