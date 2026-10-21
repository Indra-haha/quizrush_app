import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hero halaman gabung room: logo aplikasi di kotak gradient, judul, dan
/// subjudul ajakan memasukkan PIN.
class JoinGameHero extends StatelessWidget {
  const JoinGameHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _LogoTile(),
        const SizedBox(height: AppSpacing.space6),
        Text(
          'Siap Main?',
          textAlign: TextAlign.center,
          style: AppTextStyles.joinTitle,
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Masukkan PIN permainan untuk bergabung',
          textAlign: TextAlign.center,
          style: AppTextStyles.joinSubtitle,
        ),
      ],
    );
  }
}

/// Kotak logo 128x128 dengan gradient brand dan bayangan lembut.
class _LogoTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      transform: Matrix4.identity()..rotateZ(0.05),
      width: 128,
      height: 128,
      decoration: ShapeDecoration(
        gradient: AppGradients.logoTile,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(48)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 134.52,
              height: 134.52,
              decoration: ShapeDecoration(
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(48),
                ),
                shadows: AppShadows.pillButton,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space7),
              child: Image.asset(
                'lib/assets/icon/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
