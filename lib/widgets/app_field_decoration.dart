import 'package:flutter/material.dart';

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
      fillColor: AppColors.divider,
      labelStyle: AppTextStyles.statLabelOnPrimary.copyWith(
        color: AppColors.textSecondary,
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
          AppTextStyles.heading5.copyWith(color: AppColors.textMuted),
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space10,
        vertical: AppSpacing.space9,
      ),
      border: _outline(AppColors.divider),
      enabledBorder: _outline(AppColors.divider),
      focusedBorder: _outline(AppColors.primary),
    );
  }

  OutlineInputBorder _outline(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(radius),
      borderSide: BorderSide(color: color, width: AppBorderWidth.regular),
    );
  }
}
