import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../theme/quiz_status.dart';
import 'app_hero_card.dart';
import 'app_pill.dart';
import 'app_stat_tile.dart';

/// Kartu hero pada halaman detail kuis: status, judul, deskripsi, dan statistik.
class QuizDetailHero extends StatelessWidget {
  final Quizes quiz;

  const QuizDetailHero({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final status = _quizStatus(quiz);
    final palette = QuizStatus.palette(status);

    return AppHeroCard(
      padding: const EdgeInsets.all(AppSpacing.space10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                text: QuizStatus.labelOf(status),
                background: AppColors.textOnPrimary.withValues(alpha: 0.90),
                foreground: AppColors.primary,
                dot: palette.fg,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            quiz.title,
            style: AppTextStyles.heading1.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            AppHeroSubtitle(quiz.description),
          ],
          const SizedBox(height: AppSpacing.space9),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: AppStatTile.stacked(
                    icon: Icons.timer_outlined,
                    value: formatDuration(totalDuration(quiz)),
                    label: 'Durasi',
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: AppStatTile.stacked(
                    icon: Icons.list_alt,
                    value: '${quiz.questions.length}',
                    label: 'Pertanyaan',
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: AppStatTile.stacked(
                    icon: Icons.checklist_rtl,
                    value: 'Pilihan Ganda',
                    label: 'Tipe',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _quizStatus(Quizes quiz) {
    if (quiz.status.isNotEmpty) return quiz.status;
    const priority = ['in-Game', 'open', 'ended'];
    for (final status in priority) {
      if (quiz.rooms.any(
        (room) => room.status == status && room.status != 'waiting',
      )) {
        return status;
      }
    }
    return '';
  }
}
