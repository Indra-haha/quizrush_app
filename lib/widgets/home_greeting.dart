import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Sapaan pembuka beranda dengan nama pengguna opsional.
class HomeGreeting extends StatelessWidget {
  final String name;

  const HomeGreeting({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Selamat Datang,', style: AppTextStyles.accentLabel),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          name.isEmpty ? 'Halo! 👋' : 'Halo, $name! 👋',
          style: AppTextStyles.homeGreeting,
        ),
      ],
    );
  }
}
