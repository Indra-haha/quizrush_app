import 'package:flutter/material.dart';

import '../../helpers/quiz_play_session.dart';
import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_option_theme.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quiz_answer_banner.dart';
import '../../widgets/quiz_countdown_dial.dart';
import '../../widgets/quiz_option_tile.dart';
import '../../widgets/quiz_question_card.dart';
import '../../widgets/quiz_test_header.dart';

/// Halaman test lokal: satu soal, timer, dan empat pilihan jawaban. Semua
/// aturan permainan ada di [QuizPlaySession], halaman ini hanya merender.
class QuizTestPage extends StatefulWidget {
  final Quizes quiz;

  const QuizTestPage({super.key, required this.quiz});

  @override
  State<QuizTestPage> createState() => _QuizTestPageState();
}

class _QuizTestPageState extends State<QuizTestPage> {
  late final QuizPlaySession _session =
      QuizPlaySession(questions: widget.quiz.questions)
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space9,
            AppSpacing.none,
            AppSpacing.space9,
            AppSpacing.space10,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuizTestHeader(
                title: widget.quiz.title,
                currentIndex: _session.currentIndex,
                totalQuestions: _session.totalQuestions,
                maxScore: _session.currentMaxScore,
                totalScore: _session.totalScore,
              ),
              _buildTimer(),
              QuizQuestionCard(question: _session.currentQuestion.question),
              const SizedBox(height: AppSpacing.space8),
              _buildOptions(),
              if (_session.isAnswered && _session.isUserCorrect != null) ...[
                const SizedBox(height: AppSpacing.space4),
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

  Widget _buildTimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Center(child: QuizCountdownDial(seconds: _session.timeLeft)),
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
