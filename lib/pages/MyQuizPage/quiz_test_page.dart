import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../helpers/quiz_play_session.dart';
import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_option_theme.dart';
import '../../widgets/app_pill.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quiz_answer_banner.dart';
import '../../widgets/quiz_countdown_dial.dart';
import '../../widgets/quiz_option_tile.dart';

/// Halaman test lokal: satu soal, timer, dan empat pilihan jawaban. Semua
/// aturan permainan ada di [QuizPlaySession], halaman ini hanya merender.
class QuizTestPage extends StatefulWidget {
  final Quizes quiz;

  const QuizTestPage({super.key, required this.quiz});

  @override
  State<QuizTestPage> createState() => _QuizTestPageState();
}

class _QuizTestPageState extends State<QuizTestPage> {
  late final QuizPlaySession _session = QuizPlaySession(
    questions: widget.quiz.questions,
  )
    ..onChanged = _onSessionChanged
    ..onFinished = _onSessionFinished;

  @override
  void initState() {
    super.initState();
    _session.start();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  void _onSessionFinished() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kuis Selesai!'),
        content: Text('Total Poin Kamu: ${_session.totalScore}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  QuizOptionState _stateFor(int index) {
    final session = _session;
    if (!session.isAnswered) {
      return session.selectedAnswerIndex == index
          ? QuizOptionState.selected
          : QuizOptionState.idle;
    }
    if (index == session.correctIndex) return QuizOptionState.correct;
    if (index == session.selectedAnswerIndex) return QuizOptionState.wrong;
    return QuizOptionState.dimmed;
  }

  @override
  Widget build(BuildContext context) {
    if (_session.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: const EmptyStateView(
          icon: Icons.quiz_outlined,
          message: 'Tidak ada soal dalam kuis ini.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Testing (Modular Engine)')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildTimer(),
              _buildQuestionCard(),
              const SizedBox(height: 16),
              _buildOptions(),
              if (_session.isAnswered && _session.isUserCorrect != null) ...[
                const SizedBox(height: 8),
                QuizAnswerBanner(
                  isCorrect: _session.isUserCorrect!,
                  gainedScore: _session.gainedScore,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.quiz.title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                  letterSpacing: 0.60,
                ),
              ),
              const SizedBox(height: 4),
              AppPill(
                text: 'Soal ${_session.currentIndex + 1}',
                trailingText: '/ ${_session.totalQuestions}',
                trailingColor: AppColors.muted,
                background: AppColors.heroBg,
                foreground: AppColors.ink,
                dot: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          Row(
            children: [
              AppStatTile.compact(
                value: 'Max ${_session.currentMaxScore} pts',
                bg: AppColors.neutralBg,
                fg: AppColors.neutralDark,
                fontSize: 12,
                borderColor: AppColors.borderSlate,
              ),
              const SizedBox(width: 8),
              AppStatTile.compact(
                value: '${_session.totalScore}',
                bg: AppColors.warmSurface,
                fg: AppColors.warmInk,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(child: QuizCountdownDial(seconds: _session.timeLeft)),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowHairline,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Text(
          _session.currentQuestion.question,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            color: AppColors.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.38,
          ),
        ),
      ),
    );
  }

  Widget _buildOptions() {
    final options = _session.currentQuestion.options;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < options.length; index++)
          QuizOptionTile(
            label: options[index],
            letter: String.fromCharCode(65 + index % optionThemes.length),
            theme: optionThemes[index % optionThemes.length],
            state: _stateFor(index),
            onTap: _session.isAnswered ? null : () => _session.answer(index),
          ),
      ],
    );
  }
}
