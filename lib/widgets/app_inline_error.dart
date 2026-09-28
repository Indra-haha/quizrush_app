import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Pesan error kecil di bawah form, menggantikan `TextStyle` inline yang
/// sebelumnya ditulis ulang di setiap sheet/form.
class AppInlineError extends StatelessWidget {
  final String message;

  const AppInlineError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: GoogleFonts.plusJakartaSans(
        color: AppColors.dangerInk,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.50,
      ),
    );
  }
}
