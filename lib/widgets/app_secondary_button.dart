import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        backgroundColor: AppColors.cardBg,
        side: const BorderSide(color: AppColors.border, width: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: const BoxDecoration(
              color: AppColors.highlight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
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
