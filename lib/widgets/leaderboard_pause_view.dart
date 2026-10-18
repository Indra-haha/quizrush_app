import 'dart:async';

import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../models/live_game.dart';
import '../theme/app_theme.dart';
import 'app_pill.dart';

/// Papan jeda antar soal: ringkasan hasil satu ronde, kartu peringkat diri
/// sendiri, dan daftar Top 5 peserta, lengkap dengan hitung mundur menuju soal
/// berikutnya.
class LeaderboardPauseView extends StatefulWidget {
  final int round;
  final int total;
  final int nextInMs;
  final List<LiveLeaderboardEntry> leaderboard;
  final String myUsername;

  /// True bila penampil adalah host: kartu "ANDA" disembunyikan karena host
  /// bukan peserta dan tidak punya entri di papan peringkat.
  final bool isHost;

  const LeaderboardPauseView({
    super.key,
    required this.round,
    required this.total,
    required this.nextInMs,
    required this.leaderboard,
    required this.myUsername,
    this.isHost = false,
  });

  @override
  State<LeaderboardPauseView> createState() => _LeaderboardPauseViewState();
}

class _LeaderboardPauseViewState extends State<LeaderboardPauseView> {
  late int _secondsLeft;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _secondsLeft = (widget.nextInMs / 1000).ceil().clamp(0, 9999).toInt();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 0) {
        _ticker?.cancel();
        return;
      }
      if (mounted) setState(() => _secondsLeft--);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isLast => widget.total > 0 && widget.round >= widget.total - 1;

  LiveLeaderboardEntry? get _self {
    for (final entry in widget.leaderboard) {
      if (entry.username == widget.myUsername) return entry;
    }
    return null;
  }

  String _pct(LiveLeaderboardEntry entry) =>
      '${(entry.accuracy * 100).toStringAsFixed(1)}%';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space8,
          AppSpacing.space6,
          AppSpacing.space8,
          AppSpacing.space12,
        ),
        children: [
          _topHeader(),
          const SizedBox(height: AppSpacing.space8),
          _headline(),
          const SizedBox(height: AppSpacing.space6),
          _countdownPill(),
          const SizedBox(height: AppSpacing.space8),
          if (!widget.isHost) ...[
            _selfCard(),
            const SizedBox(height: AppSpacing.space8),
          ],
          _topFiveHeader(),
          const SizedBox(height: AppSpacing.space4),
          ..._topFiveRows(),
        ],
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        AppPill(
          text: 'SOAL ${widget.round + 1} DARI ${widget.total}',
          background: AppColors.primarySoft,
          foreground: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
            vertical: AppSpacing.space2,
          ),
        ),
        const Spacer(),
        Text(
          'Leaderboard Round Standings',
          style: AppTextStyles.bodyCaption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: AppFontWeight.semibold,
          ),
        ),
      ],
    );
  }

  Widget _headline() {
    return Column(
      children: [
        Text(
          'RONDE ${widget.round + 1} SELESAI',
          textAlign: TextAlign.center,
          style: AppTextStyles.accentCaption.copyWith(letterSpacing: 2),
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Papan Peringkat',
          textAlign: TextAlign.center,
          style: AppTextStyles.heading1,
        ),
      ],
    );
  }

  Widget _countdownPill() {
    final label = _isLast
        ? 'Menyiapkan hasil akhir...'
        : '$_secondsLeft dtk menuju soal ${widget.round + 2}';
    return Center(
      child: AppPill(
        text: label,
        icon: Icons.timer_outlined,
        background: AppColors.primary,
        foreground: AppColors.textOnPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space6,
          vertical: AppSpacing.space4,
        ),
      ),
    );
  }

  Widget _selfCard() {
    final self = _self;
    final rank = self?.rank ?? 0;
    final name = self?.displayName ?? 'Kamu';
    final pct = self == null ? '-' : _pct(self);
    final score = self?.score ?? 0;
    final correct = self?.correct ?? 0;
    final answered = self?.answered ?? 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Text(
            rank > 0 ? '#$rank' : '—',
            style: AppTextStyles.statValueOnPrimary,
          ),
          const SizedBox(width: AppSpacing.space6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading5.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.textOnPrimary.withValues(alpha: 0.22),
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        'ANDA',
                        style: AppTextStyles.statLabelOnPrimary.copyWith(
                          fontSize: AppFontSize.caption,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '$pct ($correct/$answered)',
                  style: AppTextStyles.statLabelOnPrimary.copyWith(
                    fontWeight: AppFontWeight.regular,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatPoints(score),
                style: AppTextStyles.statValueOnPrimary,
              ),
              Text(
                'PTS',
                style: AppTextStyles.statLabelOnPrimary.copyWith(
                  fontWeight: AppFontWeight.regular,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _topFiveHeader() {
    return Row(
      children: [
        Text(
          'TOP 5 PESERTA',
          style: AppTextStyles.accentCaption.copyWith(letterSpacing: 1.2),
        ),
        const Spacer(),
        Text(
          'Total ${widget.leaderboard.length}',
          style: AppTextStyles.bodyCaption,
        ),
      ],
    );
  }

  List<Widget> _topFiveRows() {
    final top = widget.leaderboard.take(5).toList();
    if (top.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.textOnPrimary,
            border: Border.all(
              color: AppColors.primaryBorder.withValues(alpha: 0.4),
            ),
            borderRadius: AppRadius.md,
          ),
          child: Text('Belum ada peserta.', style: AppTextStyles.bodyCaption),
        ),
      ];
    }
    return [for (final entry in top) _rankRow(entry)];
  }

  Widget _rankRow(LiveLeaderboardEntry entry) {
    final isSelf = entry.username == widget.myUsername;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
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
            width: 28,
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
                  '${_pct(entry)} (${entry.correct}/${entry.answered})',
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
