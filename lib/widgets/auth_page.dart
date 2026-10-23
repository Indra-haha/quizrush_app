import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Shell halaman auth (login & register).
///
/// Menyusun hero gradien di atas, wordmark + tagline, lalu kartu form putih
/// yang menumpuk ke hero. Isi kartu diberikan lewat [cardChildren].
class AuthPageScaffold extends StatelessWidget {
  final List<Widget> cardChildren;

  const AuthPageScaffold({super.key, required this.cardChildren});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBase,
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSizes.authPageMinHeight,
          ),
          child: Stack(
            children: [
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AuthHeroPanel(),
              ),
              Padding(
                padding: const EdgeInsets.only(top: AppSizes.authHeroTop),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuthBrandHeader(),
                    const SizedBox(height: AppSpacing.space13),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space8,
                      ),
                      child: AuthFormCard(children: cardChildren),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panel gradien di bagian atas halaman auth.
///
/// Panel setinggi 242px dengan sudut bawah membulat 32px dan dua lingkaran
/// dekoratif putih 10% seperti pada desain.
class AuthHeroPanel extends StatelessWidget {
  const AuthHeroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppSizes.authHero,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: ShapeDecoration(
                gradient: AppGradients.authHero,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.authHero),
              ),
            ),
          ),
          const Positioned(
            left: 326,
            top: -64,
            child: Opacity(
              opacity: 0.10,
              child: _HeroBubble(width: 128, height: 128),
            ),
          ),
          const Positioned(
            left: -48,
            top: 194,
            child: Opacity(
              opacity: 0.10,
              child: _HeroBubble(width: 96, height: 96),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBubble extends StatelessWidget {
  final double width;
  final double height;

  const _HeroBubble({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(
        color: AppColors.pureSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      ),
    );
  }
}

/// Wordmark aplikasi dan tagline di atas panel gradien.
class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppSpacing.space4,
          children: [
            Image.asset(
              'lib/assets/icon/logo.png',
              width: AppIconSize.xxl,
              height: AppIconSize.xxl,
              fit: BoxFit.contain,
            ),
            Text(
              'QUIZRUSH',
              textAlign: TextAlign.center,
              style: AppTextStyles.brandWordmark,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space4),
          child: Opacity(
            opacity: 0.90,
            child: Text(
              'Mulai petualangan cerdasmu sekarang!',
              textAlign: TextAlign.center,
              style: AppTextStyles.heroTagline,
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu putih berisi form auth.
class AuthFormCard extends StatelessWidget {
  final List<Widget> children;

  const AuthFormCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space10),
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppColors.pureSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.authCard),
        shadows: AppShadows.authCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        spacing: AppSpacing.space16,
        children: children,
      ),
    );
  }
}

/// Judul kartu form ("Login" / "Buat Akun") beserta spasi ke field pertama.
class AuthFormTitle extends StatelessWidget {
  final String title;

  const AuthFormTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.space2,
      children: [
        Text(title, style: AppTextStyles.authTitle),
        SizedBox(width: double.infinity, height: AppSpacing.space10),
      ],
    );
  }
}

/// Baris penutup form: teks biasa + tautan aksi, rata tengah horizontal.
class AuthPageFooter extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback? onLinkTap;

  const AuthPageFooter({
    super.key,
    required this.text,
    required this.linkText,
    this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space4),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.space2,
        runSpacing: AppSpacing.space1,
        children: [
          Text(text, style: AppTextStyles.bodySecondary),
          GestureDetector(
            onTap: onLinkTap,
            child: Text(linkText, style: AppTextStyles.authFooterLink),
          ),
        ],
      ),
    );
  }
}
