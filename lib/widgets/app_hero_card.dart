import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kartu hero dengan gradient dan shadow yang sama di semua halaman detail.
class AppHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final bool elevated;

  const AppHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.space9),
    this.margin,
    this.radius = 32,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        gradient: AppGradients.solidHero,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated ? AppShadows.brandGlow : null,
      ),
      child: child,
    );
  }
}

/// Judul besar di dalam hero card, warna putih.
class AppHeroTitle extends StatelessWidget {
  final String text;
  final double fontSize;

  const AppHeroTitle(this.text, {super.key, this.fontSize = 24});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.display1.copyWith(color: AppColors.textOnPrimary),
    );
  }
}

/// Teks deskripsi di bawah judul hero.
class AppHeroSubtitle extends StatelessWidget {
  final String text;
  final double fontSize;

  const AppHeroSubtitle(
    this.text, {
    super.key,
    this.fontSize = AppFontSize.small,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.statLabelOnPrimary.copyWith(
        color: AppColors.textOnPrimary.withValues(alpha: 0.80),
      ),
    );
  }
}
