import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Wordmark aplikasi "bolt QUIZRUSH" pada header halaman gabung room.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      spacing: AppSpacing.space4,
      children: [
        Flexible(
          child: Text(
            'bolt',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.wordmark,
          ),
        ),
        Flexible(
          child: Text(
            'QUIZRUSH',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.wordmarkItalic,
          ),
        ),
      ],
    );
  }
}
