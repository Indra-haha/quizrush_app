import 'package:flutter/material.dart';

import '../../helpers/format.dart';
import '../../models/live_game.dart';
import '../../services/points_store.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_primary_button.dart';

/// Halaman hasil akhir setelah permainan live selesai: podium tiga besar,
/// daftar lengkap peserta, ringkasan pencapaian diri, dan total poin yang
/// didapatkan.
class QuizResultPage extends StatelessWidget {
  final LiveGameEnd result;
  final String myUsername;
  final int myScore;
  final int myCorrect;
  final int myAnswered;
  final String roomTitle;

  const QuizResultPage({
    super.key,
    required this.result,
    required this.myUsername,
    required this.myScore,
    required this.myCorrect,
    required this.myAnswered,
    required this.roomTitle,
  });

  LiveLeaderboardEntry? get _self {
    for (final entry in result.leaderboard) {
      if (entry.username == myUsername) return entry;
    }
    return null;
  }

  double get _accuracy => myAnswered > 0 ? myCorrect / myAnswered : 0;

  void _finish(BuildContext context) {
    PointsStore.instance.refresh();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBar(
        title: 'Hasil Akhir',
        leading: IconButton(
          onPressed: () => _finish(context),
          icon: const Icon(Icons.close),
          color: AppColors.primary,
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space8,
            AppSpacing.space6,
            AppSpacing.space8,
            AppSpacing.space12,
          ),
          children: [
            _summaryCard(),
            const SizedBox(height: AppSpacing.space8),
            _podium(),
            const SizedBox(height: AppSpacing.space8),
            _fullList(),
            const SizedBox(height: AppSpacing.space8),
            AppPrimaryButton(
              label: 'Selesai',
              icon: Icons.check_circle_outline,
              onPressed: () => _finish(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    final self = _self;
    final rank = self?.rank ?? 0;
    final total = result.leaderboard.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text(
            roomTitle.toUpperCase(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.statLabelOnPrimary.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            rank > 0 ? '#$rank' : '—',
            style: AppTextStyles.displayHero.copyWith(
              color: AppColors.textOnPrimary,
              fontSize: 56,
            ),
          ),
          Text(
            total > 0 ? 'dari $total peserta' : 'peserta',
            style: AppTextStyles.statLabelOnPrimary.copyWith(
              fontWeight: AppFontWeight.regular,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Row(
            children: [
              Expanded(
                child: _summaryStat(
                  'AKURASI',
                  '${(_accuracy * 100).toStringAsFixed(0)}%',
                  '$myCorrect/$myAnswered',
                ),
              ),
              Container(
                width: AppBorderWidth.hairline,
                height: 48,
                color: AppColors.textOnPrimary.withValues(alpha: 0.25),
              ),
              Expanded(
                child: _summaryStat(
                  'POIN DIDAPAT',
                  formatPoints(myScore),
                  'PTS',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryStat(String label, String value, String caption) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.statLabelOnPrimary.copyWith(
            fontSize: AppFontSize.caption,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(value, style: AppTextStyles.statValueOnPrimary),
        Text(
          caption,
          style: AppTextStyles.statLabelOnPrimary.copyWith(
            fontWeight: AppFontWeight.regular,
          ),
        ),
      ],
    );
  }

  Widget _podium() {
    if (result.leaderboard.isEmpty) return const SizedBox.shrink();

    final list = result.leaderboard;
    final first = list.isNotEmpty ? list[0] : null;
    final second = list.length > 1 ? list[1] : null;
    final third = list.length > 2 ? list[2] : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _podiumSpot(second, 2, 92)),
        const SizedBox(width: AppSpacing.space3),
        Expanded(child: _podiumSpot(first, 1, 128)),
        const SizedBox(width: AppSpacing.space3),
        Expanded(child: _podiumSpot(third, 3, 74)),
      ],
    );
  }

  Widget _podiumSpot(LiveLeaderboardEntry? entry, int rank, double height) {
    final color = switch (rank) {
      1 => AppColors.warning,
      2 => AppColors.info,
      _ => AppColors.primaryBorder,
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry != null) ...[
          Text(_medal(rank), style: const TextStyle(fontSize: 26)),
          const SizedBox(height: AppSpacing.space2),
          Text(
            entry.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelStrongSmall,
          ),
          Text(
            formatPoints(entry.score),
            style: AppTextStyles.bodyCaption.copyWith(
              color: AppColors.primaryDark,
              fontWeight: AppFontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
        ] else
          const SizedBox(height: 58),
        Container(
          height: height,
          width: double.infinity,
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: AppSpacing.space4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          child: Text(
            '$rank',
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fullList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'KLASEMEN LENGKAP',
          style: AppTextStyles.accentCaption.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: AppSpacing.space4),
        for (final entry in result.leaderboard) _rankRow(entry),
      ],
    );
  }

  Widget _rankRow(LiveLeaderboardEntry entry) {
    final isSelf = entry.username == myUsername;
    final pct = entry.answered > 0
        ? '${(entry.accuracy * 100).toStringAsFixed(0)}%'
        : '-';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: isSelf ? AppColors.primarySoft : AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: isSelf ? 0.7 : 0.4),
          width: isSelf ? AppBorderWidth.thin : AppBorderWidth.hairline,
        ),
        borderRadius: AppRadius.md,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _medal(entry.rank),
              textAlign: TextAlign.center,
              style: AppTextStyles.labelStrong,
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelStrong,
                ),
                Text(
                  '$pct • ${entry.correct}/${entry.answered} benar',
                  style: AppTextStyles.bodyCaption,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space3),
          Text(
            '${formatPoints(entry.score)} PTS',
            style: AppTextStyles.labelStrongSmall.copyWith(
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  String _medal(int rank) => switch (rank) {
    1 => '🥇',
    2 => '🥈',
    3 => '🥉',
    _ => '#$rank',
  };
}
