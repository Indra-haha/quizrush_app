import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_loading_indicator.dart';
import 'app_text_field.dart';

/// Field password dengan tombol mata untuk menyembunyikan/menampilkan teks.
///
/// Status obscure dikelola di dalam widget ini.
class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool enabled;
  final ValueChanged<String>? onSubmitted;

  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.icon = Icons.lock,
    this.enabled = true,
    this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      label: widget.label,
      icon: widget.icon,
      obscureText: _obscure,
      enabled: widget.enabled,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }
}

/// Field form dengan label di atas kotak input (desain register & login).
///
/// Kotak memakai latar `fieldBackground` tanpa garis bawah; ikon di kiri
/// bersifat opsional dan mengikuti posisi/jarak pada desain.
class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final double iconSize;
  final double iconOffset;
  final double iconGap;
  final EdgeInsets boxPadding;
  final bool obscureText;
  final bool readOnly;
  final bool enabled;
  final TextInputType keyboardType;
  final VoidCallback? onTap;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.iconSize = AppIconSize.sm,
    this.iconOffset = AppSpacing.space15,
    this.iconGap = AppSpacing.space9,
    this.boxPadding = const EdgeInsets.only(
      top: AppSpacing.space15,
      right: AppSpacing.space15,
      bottom: AppSpacing.space15,
    ),
    this.obscureText = false,
    this.readOnly = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.space3),
        Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: AppColors.fieldBackground),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                SizedBox(width: iconOffset),
                Icon(icon, size: iconSize, color: AppColors.textSecondary),
                SizedBox(width: iconGap),
              ],
              Expanded(
                child: Padding(
                  padding: boxPadding,
                  child: TextField(
                    controller: controller,
                    style: AppTextStyles.fieldValue,
                    obscureText: obscureText,
                    readOnly: readOnly,
                    enabled: enabled,
                    keyboardType: keyboardType,
                    onTap: onTap,
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: hint,
                      hintStyle: AppTextStyles.fieldHint,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Baris persetujuan syarat & ketentuan beserta kebijakan privasi.
class AuthTermsRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AuthTermsRow({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthTermsCheckbox(value: value, onChanged: onChanged),
        const SizedBox(width: AppSpacing.space6),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Saya menyetujui ', style: AppTextStyles.bodySecondary),
                TextSpan(
                  text: 'Syarat & Ketentuan',
                  style: AppTextStyles.termsLink,
                ),
                TextSpan(text: '\nserta ', style: AppTextStyles.bodySecondary),
                TextSpan(
                  text: 'Kebijakan Privasi',
                  style: AppTextStyles.termsLink,
                ),
                TextSpan(text: ' QuizRush.', style: AppTextStyles.bodySecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kotak centang 13x13 dengan garis 1px sesuai desain.
class AuthTermsCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const AuthTermsCheckbox({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      label: 'Saya menyetujui Syarat & Ketentuan serta Kebijakan Privasi',
      child: GestureDetector(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          width: AppSizes.termsCheckbox,
          height: AppSizes.termsCheckbox,
          decoration: ShapeDecoration(
            color: value ? AppColors.primary : AppColors.pureSurface,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                width: AppBorderWidth.hairline,
                color: AppColors.checkboxStroke,
              ),
              borderRadius: AppRadius.checkbox,
            ),
          ),
          child: value
              ? const Icon(
                  Icons.check,
                  size: AppIconSize.micro,
                  color: AppColors.pureSurface,
                )
              : null,
        ),
      ),
    );
  }
}

/// Tombol utama form autentikasi dengan indikator loading.
///
/// Varian `gradient` dipakai halaman auth: tombol penuh dengan gradien
/// brand, radius kapsul, dan bayangan sesuai desain.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;
  final bool gradient;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.gradient = false,
  });

  @override
  Widget build(BuildContext context) {
    if (gradient) {
      return DecoratedBox(
        decoration: ShapeDecoration(
          gradient: AppGradients.action,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.authAction),
          shadows: AppShadows.action,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: AppRadius.authAction,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
              alignment: Alignment.center,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: AppLoadingIndicator(),
                    )
                  : Text(label, style: AppTextStyles.authAction),
            ),
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space7),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: AppLoadingIndicator(),
            )
          : Text(label, style: AppTextStyles.button),
    );
  }
}
