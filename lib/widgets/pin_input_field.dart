import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/pin.dart';
import '../theme/app_theme.dart';

/// Kolom input PIN 6 digit angka dengan gaya besar dan berjarak.
class PinInputField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const PinInputField({
    super.key,
    required this.controller,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      enabled: enabled,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
      maxLength: Pin.length,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(Pin.length),
      ],
      textAlign: TextAlign.center,
      style: AppTextStyles.code.copyWith(
        color: AppColors.primary,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '000000',
        hintStyle: AppTextStyles.code.copyWith(color: AppColors.info),
        filled: true,
        fillColor: AppColors.textOnPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space8,
          vertical: AppSpacing.space9,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppBorderWidth.regular,
          ),
        ),
      ),
    );
  }
}
