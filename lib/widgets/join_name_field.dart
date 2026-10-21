import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Kolom isian nama panggilan pada halaman gabung room.
///
/// Ikon di kanan dipakai untuk mengisi nama panggilan acak.
class JoinNameField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onRandomize;

  /// Panjang maksimum nama panggilan yang diterima.
  static const int maxLength = 24;

  const JoinNameField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onChanged,
    this.onRandomize,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      maxLength: maxLength,
      inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
      style: AppTextStyles.hintLarge.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        counterText: '',
        hintText: 'Contoh: Sang Juara',
        hintStyle: AppTextStyles.hintLarge,
        filled: true,
        fillColor: AppColors.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space10,
          vertical: AppSpacing.space9,
        ),
        suffixIcon: IconButton(
          onPressed: enabled ? onRandomize : null,
          tooltip: 'Nama acak',
          icon: const Icon(
            Icons.auto_awesome,
            size: AppIconSize.md,
            color: AppColors.primary,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.xs,
          borderSide: const BorderSide(
            color: AppColors.primaryBorder,
            width: AppBorderWidth.regular,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.xs,
          borderSide: const BorderSide(
            color: AppColors.primaryBorder,
            width: AppBorderWidth.regular,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.xs,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppBorderWidth.regular,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.xs,
          borderSide: const BorderSide(
            color: AppColors.primaryBorder,
            width: AppBorderWidth.regular,
          ),
        ),
      ),
    );
  }
}
