import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kerangka bottom sheet: sudut atas membulat, drag handle, judul, lalu konten.
class AppBottomSheet extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AppBottomSheet({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space6,
        AppSpacing.space9,
        AppSpacing.space9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(title, style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.space8),
            ...children,
          ],
        ),
      ),
    );
  }
}
