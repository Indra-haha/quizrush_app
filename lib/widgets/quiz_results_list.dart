import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/quiz_card.dart';

/// Menampilkan hasil daftar quiz (loading/error/empty/not found/searching/list).
class QuizResultsList extends StatelessWidget {
  final bool loading;
  final String? error;
  final bool notFound;
  final int? pinProgress;
  final List<Quizes> quizzes;
  final String query;
  final Future<void> Function()? onRetry;
  final ValueChanged<Quizes> onTapQuiz;

  const QuizResultsList({
    super.key,
    required this.loading,
    required this.error,
    required this.notFound,
    required this.pinProgress,
    required this.quizzes,
    required this.query,
    required this.onRetry,
    required this.onTapQuiz,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return ErrorStateView(message: error!, onRetry: onRetry);
    }

    if (notFound) return const EmptyStateView.notFound();
    if (pinProgress != null) return EmptyStateView.searching(pinProgress!);

    if (quizzes.isEmpty) {
      if (query.isEmpty) return const EmptyStateView.empty();
      return EmptyStateView.noResult(query);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space4,
        AppSpacing.space9,
        AppSpacing.scrollClearance,
      ),
      children: [
        for (var i = 0; i < quizzes.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space9),
          QuizCard(quiz: quizzes[i], onTap: () => onTapQuiz(quizzes[i])),
        ],
      ],
    );
  }
}
