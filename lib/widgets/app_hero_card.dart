import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    this.padding = const EdgeInsets.all(20),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.highlight, AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated
            ? const [
                BoxShadow(
                  color: AppColors.shadowBrand,
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
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
      style: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        height: 1.21,
      ),
    );
  }
}

/// Teks deskripsi di bawah judul hero.
class AppHeroSubtitle extends StatelessWidget {
  final String text;
  final double fontSize;

  const AppHeroSubtitle(this.text, {super.key, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        color: Colors.white.withValues(alpha: 0.80),
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        height: 1.36,
      ),
    );
  }
}
