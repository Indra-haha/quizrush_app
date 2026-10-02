import 'package:flutter/material.dart';

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
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
    );
  }
}
