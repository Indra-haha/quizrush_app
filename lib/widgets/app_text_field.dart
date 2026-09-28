import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final Widget? suffixIcon;
  final TextInputType keyboardType;
  final VoidCallback? onTap;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.suffixIcon,
    this.keyboardType = TextInputType.text,
    this.onTap,
    this.onSubmitted,
  });

  static final _textStyle = GoogleFonts.plusJakartaSans(
    color: AppColors.ink,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: _textStyle,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      onTap: onTap,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: _textStyle,
        hintStyle: _textStyle,
        prefixIcon: Icon(icon, color: AppColors.neutral),
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }
}