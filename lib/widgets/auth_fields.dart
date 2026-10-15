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

/// Tombol utama form autentikasi dengan indikator loading.
class AuthSubmitButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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

/// Kartu form autentikasi berisi logo, judul, dan konten yang di-scroll.
class AuthFormCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AuthFormCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space10),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: AppElevation.raised,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.space11),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'lib/assets/icon/logo.png',
                      width: 70,
                      height: 70,
                    ),
                    const SizedBox(height: AppSpacing.space5),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading2Strong,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
