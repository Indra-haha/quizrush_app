import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/pin.dart';
import '../theme/app_theme.dart';

/// Kolom input PIN 6 digit angka yang ditampilkan sebagai enam kotak
/// terpisah.
///
/// Input tetap dibaca dari satu [TextField] transparan di belakang kotak-kotak
/// supaya tempel (paste) dan autofill tetap bekerja, sementara yang tampil
/// adalah kotak-kotak berisi digit.
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final digits = controller.text.trim();

        return Stack(
          children: [
            // Kolom input asli: transparan, hanya menyetorkan ketikan/paste.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: _PinTextField(
                  controller: controller,
                  enabled: enabled,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < Pin.length; i++) ...[
                  if (i > 0) const SizedBox(width: AppSpacing.space4),
                  Expanded(
                    child: _PinCell(
                      digit: digits.length > i ? digits[i] : '',
                      active: enabled && i == digits.length,
                    ),
                  ),
                ],
              ],
            ),
          ],
        );
      },
    );
  }
}

/// Kolom teks tak terlihat di belakang kotak-kotak PIN.
class _PinTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const _PinTextField({
    required this.controller,
    required this.enabled,
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
      decoration: const InputDecoration(
        counterText: '',
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// Satu kotak digit PIN.
class _PinCell extends StatelessWidget {
  final String digit;
  final bool active;

  const _PinCell({required this.digit, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: AppColors.inputFill,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: AppBorderWidth.regular,
            color: active ? AppColors.primary : AppColors.primaryBorder,
          ),
          borderRadius: AppRadius.xs,
        ),
      ),
      child: Text(digit, style: AppTextStyles.heading2Strong),
    );
  }
}
