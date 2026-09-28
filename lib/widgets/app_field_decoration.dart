import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Dekorasi `InputDecoration` untuk field form di halaman create.
///
/// Dua varian yang ada sebelumnya sekarang lewat satu kelas:
/// [AppFieldDecoration.bordered] untuk form kuis (border 2px, hint besar),
/// [AppFieldDecoration.filled] untuk sheet create room (tanpa border, label
/// kecil). Keduanya berbagi warna dan tipografi dari [AppColors]/[AppTextStyles].
class AppFieldDecoration {
  final String? label;
  final String? hint;
  final TextStyle? hintStyle;
  final double radius;
  final bool bordered;

  const AppFieldDecoration.bordered({
    this.label,
    this.hint,
    this.hintStyle,
    this.radius = 19,
  }) : bordered = true;

  const AppFieldDecoration.filled({
    this.label,
    this.hint,
    this.hintStyle,
    this.radius = 12,
  }) : bordered = false;

  InputDecoration build() => bordered ? _bordered() : _filled();

  InputDecoration _filled() {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: hintStyle,
      filled: true,
      fillColor: AppColors.lineLight,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
    );
  }

  InputDecoration _bordered() {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle:
          hintStyle ??
          GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.placeholder,
          ),
      filled: true,
      fillColor: AppColors.formFieldBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      border: _outline(AppColors.border),
      enabledBorder: _outline(AppColors.border),
      focusedBorder: _outline(AppColors.primary),
    );
  }

  OutlineInputBorder _outline(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: 2),
    );
  }
}
