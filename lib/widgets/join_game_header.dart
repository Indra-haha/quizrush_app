import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'brand_wordmark.dart';

/// Header halaman gabung room: wordmark di kiri dan tombol kembali di kanan
/// (dibungkus pil bulat), tanpa AppBar.
class JoinGameHeader extends StatelessWidget {
  /// Dipanggil saat tombol kembali ditekan.
  final VoidCallback onBack;

  const JoinGameHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space9,
        vertical: AppSpacing.space8,
      ),
      decoration: const BoxDecoration(color: AppColors.surface),
      child: Stack(
        children: [
          // Bayangan tipis di balik baris header.
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.transparent,
                boxShadow: AppShadows.layeredCard,
              ),
              child: const SizedBox(height: 74),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Flexible(child: BrandWordmark()),
              _BackButton(onBack: onBack),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol kembali berbentuk pil bulat.
class _BackButton extends StatelessWidget {
  final VoidCallback onBack;

  const _BackButton({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceTint,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back,
            size: AppIconSize.md,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
