import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../theme/app_theme.dart';

/// Chip meta pada hero halaman menunggu: nilai singkat (jumlah soal, total
/// poin) diikuti ikon di dalam pil berwarna.
class QuizWaitingHeroStat {
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;

  const QuizWaitingHeroStat({
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}

/// Hero halaman menunggu: blok brand berisi kartu kaca dengan judul kuis,
/// chip meta, dan kartu GAME PIN.
class QuizWaitingHero extends StatelessWidget {
  final String title;
  final String pin;
  final List<QuizWaitingHeroStat> stats;
  final VoidCallback? onCopyPin;
  final VoidCallback? onBack;

  const QuizWaitingHero({
    super.key,
    required this.title,
    required this.pin,
    this.stats = const [],
    this.onCopyPin,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.space9,
              onBack == null ? AppSpacing.space8 : AppSpacing.space14,
              AppSpacing.space9,
              AppSpacing.space9,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: AppSizes.heroCard),
                child: _glassCard(),
              ),
            ),
          ),
          if (onBack != null)
            Positioned(
              top: AppSpacing.space4,
              left: AppSpacing.space4,
              child: _backButton(),
            ),
        ],
      ),
    );
  }

  Widget _glassCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space10),
      decoration: ShapeDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.10),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: AppBorderWidth.hairline,
            color: AppColors.textOnPrimary.withValues(alpha: 0.20),
          ),
          borderRadius: AppRadius.xxl,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (stats.isNotEmpty) ...[
            Align(alignment: Alignment.topRight, child: _statRow()),
            const SizedBox(height: AppSpacing.space9),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.displayTitle.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space9),
          _PinCard(pin: pin, onCopy: onCopyPin),
        ],
      ),
    );
  }

  Widget _statRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stats.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.space4),
          _HeroStatChip(stat: stats[i]),
        ],
      ],
    );
  }

  Widget _backButton() {
    return Material(
      color: AppColors.textOnPrimary.withValues(alpha: 0.16),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onBack,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: AppSizes.backButton,
          height: AppSizes.backButton,
          child: const Icon(
            Icons.arrow_back,
            size: AppIconSize.body,
            color: AppColors.textOnPrimary,
          ),
        ),
      ),
    );
  }
}

/// Chip meta di dalam kartu kaca hero.
class _HeroStatChip extends StatelessWidget {
  final QuizWaitingHeroStat stat;

  const _HeroStatChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: stat.background,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.value,
            style: AppTextStyles.bodyLarge.copyWith(
              color: stat.foreground,
              fontWeight: AppFontWeight.semibold,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Icon(stat.icon, size: AppIconSize.body, color: stat.foreground),
        ],
      ),
    );
  }
}

/// Kartu putih berisi kode GAME PIN. Ketuk untuk menyalin kode.
class _PinCard extends StatelessWidget {
  final String pin;
  final VoidCallback? onCopy;

  const _PinCard({required this.pin, this.onCopy});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space10,
        vertical: AppSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.pillButton,
      ),
      child: Material(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        child: InkWell(
          onTap: onCopy,
          borderRadius: AppRadius.md,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space4,
              vertical: AppSpacing.space2,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'GAME PIN',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelStrongSmall.copyWith(
                    color: AppColors.inkMuted,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Text(
                  formatKode(pin),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.display1.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu ringkasan di bawah hero: jumlah peserta, status room, dan koneksi.
///
/// Saat koneksi terputus dan [onReconnect] diisi, chip koneksi bisa diketuk
/// untuk menyambung ulang ke room.
class QuizWaitingStats extends StatelessWidget {
  final int participantCount;
  final String statusLabel;
  final bool connected;
  final VoidCallback? onReconnect;

  const QuizWaitingStats({
    super.key,
    required this.participantCount,
    this.statusLabel = 'Menunggu host',
    this.connected = true,
    this.onReconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xxl,
        boxShadow: AppShadows.softCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppSizes.statusDot,
                height: AppSizes.statusDot,
                decoration: const BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space6),
              Expanded(
                child: Text(
                  '$participantCount Peserta',
                  style: AppTextStyles.statValue,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Wrap(
            spacing: AppSpacing.space4,
            runSpacing: AppSpacing.space4,
            children: [
              _SoftChip(icon: Icons.hourglass_top, label: statusLabel),
              _SoftChip(
                icon: connected ? Icons.wifi : Icons.wifi_off,
                label: connected ? 'Tersambung' : 'Menyambung',
                onTap: connected ? null : onReconnect,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Chip lembut berlatar terang untuk status ringkas.
class _SoftChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _SoftChip({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: AppRadius.pill,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space4,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: AppIconSize.xs, color: AppColors.primary),
              const SizedBox(width: AppSpacing.space3),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMeta.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu peserta: avatar lingkaran berisi inisial dan nama peserta.
class QuizWaitingParticipant extends StatelessWidget {
  final String name;
  final bool isHost;

  const QuizWaitingParticipant({
    super.key,
    required this.name,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.participantTile,
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.textOnPrimary.withValues(alpha: 0.50),
          width: AppBorderWidth.hairline,
        ),
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.avatar,
            height: AppSizes.avatar,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.avatarSoft,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.20),
                width: AppBorderWidth.heavy,
              ),
            ),
            child: Text(
              initial,
              style: AppTextStyles.heading2.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            trimmed,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelStrong,
          ),
          if (isHost) ...[
            const SizedBox(height: AppSpacing.space1),
            Text(
              'Host',
              style: AppTextStyles.bodyCaption.copyWith(
                color: AppColors.primary,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Slot kosong di daftar peserta: menunggu peserta berikutnya bergabung.
class QuizWaitingSlot extends StatelessWidget {
  final String label;

  const QuizWaitingSlot({super.key, this.label = 'Menunggu...'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.primaryBorder,
          width: AppBorderWidth.regular,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.emptySlot,
            height: AppSizes.emptySlot,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primaryBorder,
                width: AppBorderWidth.regular,
              ),
            ),
            child: const Icon(
              Icons.add,
              size: AppIconSize.lg,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMeta.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
