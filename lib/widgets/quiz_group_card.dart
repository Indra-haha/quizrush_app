import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../helpers/format.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../theme/quiz_status.dart';
import 'app_snackbar.dart';

/// Kartu satu quiz beserta daftar room-nya (desain MyQuiz).
///
/// Header kartu menampilkan ikon, judul, meta durasi/soal, dan pill jumlah
/// room; di bawahnya daftar baris room dengan badge status, pill PIN yang bisa
/// disalin, dan tombol aksi bergantung status.
class QuizGroupCard extends StatelessWidget {
  final Quizes quiz;
  final List<RoomSummary> rooms;
  final VoidCallback? onTapHeader;
  final ValueChanged<RoomSummary>? onTapRoom;

  const QuizGroupCard({
    super.key,
    required this.quiz,
    required this.rooms,
    this.onTapHeader,
    this.onTapRoom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.lg,
        boxShadow: AppShadows.quizCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.space6),
          for (var i = 0; i < rooms.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.space5),
            _roomRow(context, rooms[i]),
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final minutes = (quiz.durationSeconds / 60).ceil();
    return InkWell(
      borderRadius: AppRadius.md,
      onTap: onTapHeader,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppSpacing.space14,
            height: AppSpacing.space14,
            decoration: BoxDecoration(
              color: AppColors.tintIcon,
              borderRadius: AppRadius.md,
            ),
            child: const Icon(
              Icons.quiz_rounded,
              size: AppIconSize.lg,
              color: AppColors.indigoActionInk,
            ),
          ),
          const SizedBox(width: AppSpacing.space6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(quiz.title, style: AppTextStyles.quizGroupTitle),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  '$minutes Menit • ${quiz.questionCount} Soal',
                  style: AppTextStyles.metaMicro,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space2,
            ),
            decoration: BoxDecoration(
              color: AppColors.indigoActionSoft,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              '${rooms.length} Room',
              style: AppTextStyles.metaMicro.copyWith(
                color: AppColors.indigoActionInk,
                fontWeight: AppFontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roomRow(BuildContext context, RoomSummary room) {
    final ended = room.status == 'ended';
    final name =
        room.judul.trim().isEmpty ? quiz.title : room.judul.trim();
    return Material(
      color: ended
          ? AppColors.tintRoom.withValues(alpha: 0.70)
          : AppColors.tintRoom,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTapRoom == null ? null : () => onTapRoom!(room),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelStrong.copyWith(
                        color: ended
                            ? AppColors.textSecondary
                            : AppColors.inkStrong,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  _statusBadge(room.status),
                ],
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                children: [
                  if (room.kode.isNotEmpty) ...[
                    _pinPill(context, room.kode),
                    const SizedBox(width: AppSpacing.space4),
                  ],
                  const Spacer(),
                  _actionButton(room.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final palette = QuizStatus.badgePalette(status);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: AppRadius.pill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == 'in-Game') ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: palette.dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.space2),
          ],
          Text(
            QuizStatus.badgeLabelOf(status),
            style: AppTextStyles.statLabelOnPrimary.copyWith(
              color: palette.fg,
              fontSize: AppFontSize.caption,
              fontWeight: AppFontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinPill(BuildContext context, String kode) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: kode));
        AppSnackBar.show(
          context,
          'Kode room disalin.',
          duration: const Duration(seconds: 1),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space5,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.textOnPrimary,
          borderRadius: AppRadius.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'PIN',
              style: AppTextStyles.bodyCaption.copyWith(
                color: AppColors.inkMuted,
                fontWeight: AppFontWeight.semibold,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              formatKode(kode),
              style: AppTextStyles.roomCode.copyWith(
                fontSize: AppFontSize.body,
                fontWeight: AppFontWeight.bold,
                letterSpacing: 0.65,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String status) {
    final (label, bg, fg) = switch (status) {
      'waiting' => ('Mulai Room', AppColors.indigoActionSoft, AppColors.indigoActionInk),
      'open' => ('Mulai Game', AppColors.indigoActionSoft, AppColors.indigoActionInk),
      'in-Game' => ('Pantau Live', AppColors.indigoAction, AppColors.textOnPrimary),
      'ended' => ('Lihat Hasil', AppColors.endedTint, AppColors.inkStrong),
      _ => ('Lihat Detail', AppColors.indigoActionSoft, AppColors.indigoActionInk),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.sm,
        boxShadow: status == 'in-Game' ? AppShadows.hairlineTight : null,
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppTextStyles.bodyMeta.copyWith(color: fg),
      ),
    );
  }
}
