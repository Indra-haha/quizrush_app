import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  final Color color;

  const AppLoadingIndicator({
    super.key,
    this.strokeWidth = 2,
    this.color = AppColors.textOnPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(strokeWidth: strokeWidth, color: color);
  }
}
