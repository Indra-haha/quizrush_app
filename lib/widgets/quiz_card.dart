import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../theme/quiz_status.dart';
import '../helpers/format.dart';

/// Varian tampilan kartu kuis.
///
/// [standard] dipakai halaman hasil; [home] mengikuti desain beranda baru
/// (sudut lebih besar, badge kategori di kiri atas, kotak ikon di tengah).
enum QuizCardStyle { standard, home }

class QuizCard extends StatelessWidget {
  final Quizes quiz;
  final VoidCallback onTap;
  final QuizCardStyle style;

  const QuizCard({
    super.key,
    required this.quiz,
    required this.onTap,
    this.style = QuizCardStyle.standard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.primaryBorder,
        ),
        boxShadow: AppShadows.softLift,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCover(),
              Padding(
                padding: EdgeInsets.all(AppSpacing.space8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quiz.title,
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: AppSpacing.space4),
                    Row(
                      children: [
                        _buildMeta(
                          Icons.sports_esports,
                          '${quiz.rooms.length} Main',
                        ),
                        if (quiz.createdAt.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.space6),
                          _buildMeta(
                            Icons.access_time,
                            relativeTime(quiz.createdAt),
                          ),
                        ],
                      ],
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

  Widget _buildCover() {
    return SizedBox(
      height: AppSizes.homeQuizCover,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (quiz.path.isEmpty)
            _buildCoverPlaceholder()
          else
            Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  quiz.path,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildCoverPlaceholder(),
                  loadingBuilder: (context, child, progress) =>
                      progress == null ? child : _buildCoverPlaceholder(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (quiz.status.isNotEmpty)
                    _buildBadge(QuizStatus.labelOf(quiz.status)),
                  const SizedBox(height: AppSpacing.space2),
                  _buildBadge('${quiz.questionCount} Soal'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCoverPlaceholder() {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppGradients.heroGradient),
      child: Center(
        child: Icon(
          Icons.quiz,
          size: AppIconSize.illustration,
          color: AppColors.onLightAlpha,
        ),
      ),
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.50),
        borderRadius: AppRadius.md,
      ),
      child: Text(text, style: AppTextStyles.statLabelOnPrimary),
    );
  }

  Widget _buildHomeBadge(String text, {bool outlined = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: outlined
            ? AppColors.overlayLight
            : AppColors.textPrimary.withValues(alpha: 0.50),
        borderRadius: AppRadius.pill,
        border: outlined
            ? Border.all(
                color: AppColors.overlayBorder,
                width: AppBorderWidth.hairline,
              )
            : null,
      ),
      child: Text(text, style: AppTextStyles.statLabelOnPrimary),
    );
  }

  Widget _buildMeta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppIconSize.xs, color: AppColors.textSecondary),
        const SizedBox(width: AppSpacing.space2),
        Text(text, style: AppTextStyles.bodyMeta),
      ],
    );
  }
}

class _QuizCardIconBox extends StatelessWidget {
  const _QuizCardIconBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSizes.homeQuizIconBox,
      height: AppSizes.homeQuizIconBox,
      decoration: BoxDecoration(
        color: AppColors.overlayLight,
        borderRadius: AppRadius.lg,
        border: Border.all(
          color: AppColors.overlayBorder,
          width: AppBorderWidth.hairline,
        ),
      ),
      child: const Icon(
        Icons.menu_book_rounded,
        size: AppIconSize.xxl,
        color: AppColors.textOnPrimary,
      ),
    );
  }
}
