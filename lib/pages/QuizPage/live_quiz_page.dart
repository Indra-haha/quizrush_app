import 'package:flutter/material.dart';

import '../../helpers/format.dart';
import '../../models/live_game.dart';
import '../../models/room.dart';
import '../../services/live_game_controller.dart';
import '../../services/room_socket.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_option_theme.dart';
import '../../widgets/app_pill.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/leaderboard_pause_view.dart';
import '../../widgets/quiz_answer_banner.dart';
import '../../widgets/quiz_countdown_dial.dart';
import '../../widgets/quiz_option_tile.dart';
import '../../widgets/quiz_question_card.dart';
import '../../widgets/quiz_test_header.dart';
import 'quiz_result_page.dart';

/// Halaman permainan live: merender soal aktif, timer, dan pilihan jawaban;
/// menampilkan papan jeda antar soal; lalu berpindah ke hasil akhir saat kuis
/// selesai. Seluruh aturan permainan ada di [LiveGameController].
///
/// Untuk host ([isHost] true), sesi soal tidak menampilkan view peserta
/// (soal / opsi / jawaban); host hanya melihat progress soal dan papan
/// peringkat sementara.
class LiveQuizPage extends StatefulWidget {
  final Room room;
  final RoomSocket socket;
  final String loginToken;
  final String myUsername;
  final String myNama;
  final LiveQuestion initialQuestion;
  final bool isHost;

  const LiveQuizPage({
    super.key,
    required this.room,
    required this.socket,
    required this.loginToken,
    required this.myUsername,
    required this.myNama,
    required this.initialQuestion,
    this.isHost = false,
  });

  @override
  State<LiveQuizPage> createState() => _LiveQuizPageState();
}

class _LiveQuizPageState extends State<LiveQuizPage> {
  late final LiveGameController _controller;
  bool _navHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = LiveGameController(
      socket: widget.socket,
      roomKode: widget.room.kode,
      loginToken: widget.loginToken,
      myUsername: widget.myUsername,
      isHost: widget.isHost,
      initialQuestion: widget.initialQuestion,
    );
    _controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;

    if (_controller.phase == LivePhase.ended && !_navHandled) {
      _navHandled = true;
      final end = _controller.gameEnd;
      if (end != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultPage(
              result: end,
              myUsername: widget.myUsername,
              myScore: _controller.totalScore,
              myCorrect: _controller.correctCount,
              myAnswered: _controller.answeredCount,
              roomTitle: widget.room.displayTitle,
              isHost: widget.isHost,
            ),
          ),
        );
      }
      return;
    }
    setState(() {});
  }

  QuizOptionState _stateFor(int index) {
    final controller = _controller;
    if (!controller.answered) {
      return controller.selectedIndex == index
          ? QuizOptionState.selected
          : QuizOptionState.idle;
    }
    final question = controller.question;
    if (question == null) return QuizOptionState.dimmed;
    if (index == question.correctIdx) return QuizOptionState.correct;
    if (index == controller.selectedIndex) return QuizOptionState.wrong;
    return QuizOptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    final pause = _controller.roundResult;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBar(
        title: widget.room.displayTitle,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
          color: AppColors.primary,
        ),
      ),
      body: switch (_controller.phase) {
        LivePhase.pause when pause != null => LeaderboardPauseView(
          round: pause.round,
          total: pause.total,
          nextInMs: pause.nextInMs,
          leaderboard: pause.leaderboard,
          myUsername: widget.myUsername,
          isHost: widget.isHost,
        ),
        LivePhase.ended => const Center(child: CircularProgressIndicator()),
        _ => widget.isHost ? _buildHostDashboard() : _buildQuestion(),
      },
    );
  }

  Widget _buildQuestion() {
    final question = _controller.question;
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space4,
        AppSpacing.space8,
        AppSpacing.space10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuizTestHeader(
            title: widget.room.displayTitle,
            currentIndex: question.index,
            totalQuestions: question.total,
            maxScore: question.maxScore,
            totalScore: _controller.totalScore,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: QuizCountdownDial(seconds: _controller.timeLeft),
            ),
          ),
          QuizQuestionCard(question: question.question),
          const SizedBox(height: AppSpacing.space8),
          _buildOptions(question),
          if (_controller.answered && _controller.isCorrect != null) ...[
            const SizedBox(height: AppSpacing.space4),
            QuizAnswerBanner(
              isCorrect: _controller.isCorrect!,
              gainedScore: _controller.gainedScore,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptions(LiveQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < question.options.length; index++)
          QuizOptionTile(
            label: question.options[index],
            letter: String.fromCharCode(65 + index % optionThemes.length),
            theme: optionThemes[index % optionThemes.length],
            state: _stateFor(index),
            onTap: _controller.answered
                ? null
                : () => _controller.answer(index),
          ),
      ],
    );
  }

  /// Dashboard host selama sesi soal berjalan: progress soal + timer +
  /// papan peringkat sementara (tanpa soal maupun opsi jawaban).
  Widget _buildHostDashboard() {
    final question = _controller.question;
    if (question == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space4,
        AppSpacing.space8,
        AppSpacing.space10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _hostHeader(question),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
            child: Center(
              child: QuizCountdownDial(seconds: _controller.timeLeft),
            ),
          ),
          _hostStandingsHeader(),
          const SizedBox(height: AppSpacing.space4),
          ..._hostStandingsRows(),
        ],
      ),
    );
  }

  Widget _hostHeader(LiveQuestion question) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.room.displayTitle.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelStrongSmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              AppPill(
                text: 'Soal ${question.index + 1}',
                trailingText: '/ ${question.total}',
                trailingColor: AppColors.textSecondary,
                background: AppColors.surfaceSoft,
                foreground: AppColors.textPrimary,
                dot: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space2,
                ),
              ),
            ],
          ),
        ),
        AppPill(
          text: 'MODE HOST',
          background: AppColors.primary,
          foreground: AppColors.textOnPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space5,
            vertical: AppSpacing.space2,
          ),
        ),
      ],
    );
  }

  Widget _hostStandingsHeader() {
    return Row(
      children: [
        Text(
          'PERINGKAT SEMENTARA',
          style: AppTextStyles.accentCaption.copyWith(letterSpacing: 1.2),
        ),
        const Spacer(),
        Text(
          'Total ${_controller.lastLeaderboard.length} peserta',
          style: AppTextStyles.bodyCaption,
        ),
      ],
    );
  }

  List<Widget> _hostStandingsRows() {
    final entries = _controller.lastLeaderboard;
    if (entries.isEmpty) {
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
          child: Text(
            'Belum ada data peringkat. Menunggu ronde pertama selesai...',
            style: AppTextStyles.bodyCaption,
          ),
        ),
      ];
    }
    return [for (final entry in entries) _hostRankRow(entry)];
  }

  Widget _hostRankRow(LiveLeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.space3),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space5,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.4),
          width: AppBorderWidth.hairline,
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
                  '${(entry.accuracy * 100).toStringAsFixed(1)}% '
                  '(${entry.correct}/${entry.answered})',
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
