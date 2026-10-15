import 'package:flutter/material.dart';

import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_status.dart';
import '../../helpers/format.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_hero_card.dart';
import '../../widgets/app_pill.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/empty_state_view.dart';

class DetailQuizRoomPage extends StatelessWidget {
  final Quizes quiz;
  final String? focusKode;

  const DetailQuizRoomPage({super.key, required this.quiz, this.focusKode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBar(
        title: 'Detail Quiz',
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final rooms = quiz.rooms
        .where((room) => room.status != 'waiting' || room.kode == focusKode)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space8,
        AppSpacing.space9,
        AppSpacing.space12,
      ),
      children: [
        _heroCard(quiz),
        const SizedBox(height: AppSpacing.space10),
        _roomSectionHeader(rooms.length),
        const SizedBox(height: AppSpacing.space8),
        if (rooms.isEmpty) _emptyRooms(),
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space8),
          _roomCard(context, quiz, rooms[i], i),
        ],
        const SizedBox(height: AppSpacing.space10),
      ],
    );
  }

  Widget _heroCard(Quizes quiz) {
    final status = _quizStatus(quiz);
    final info = _statusInfo(status);

    return AppHeroCard(
      padding: const EdgeInsets.all(AppSpacing.space10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                text: info.label,
                background: AppColors.textOnPrimary.withValues(alpha: 0.90),
                foreground: AppColors.primary,
                dot: info.color,
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

  Widget _roomSectionHeader(int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Daftar Room', style: AppTextStyles.display2),
            const SizedBox(width: AppSpacing.space4),
            AppPill(
              text: '$count Room',
              background: AppColors.primarySoft,
              foreground: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space2),
        Text(
          'Pilih room untuk langsung bergabung ke server kuis',
          style: AppTextStyles.bodyMeta,
        ),
      ],
    );
  }

  Widget _roomCard(
    BuildContext context,
    Quizes quiz,
    RoomSummary room,
    int index,
  ) {
    final info = _statusInfo(room.status);
    final isFocused = room.kode == focusKode && focusKode != null;
    final subtitle = room.createdAt.isNotEmpty
        ? 'Dibuat ${relativeTime(room.createdAt)}'
        : 'Room #${index + 1}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        border: isFocused
            ? Border.all(color: AppColors.primary, width: AppBorderWidth.thin)
            : null,
        boxShadow: AppShadows.hairlineWide,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: info.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Text(
                  info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.statLabelOnPrimary.copyWith(
                    color: info.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          if (isFocused) ...[
            const AppPill(
              text: 'Room dari PIN yang kamu masukkan',
              background: AppColors.primarySoft,
              foreground: AppColors.textPrimary,
              icon: Icons.pin,
            ),
            const SizedBox(height: AppSpacing.space6),
          ],
          Text(room.judul, style: AppTextStyles.heading6),
          const SizedBox(height: AppSpacing.space3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space8),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space6,
              AppSpacing.space8,
              AppSpacing.space6,
              AppSpacing.space6,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.lg,
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIN SERVER', style: AppTextStyles.bodyMeta),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      formatKode(room.kode),
                      style: AppTextStyles.display2.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (room.status == 'open')
                  SizedBox(
                    height: 44,
                    child: AppPrimaryButton(
                      label: 'Masuk',
                      radius: 12,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space10,
                      ),
                      onPressed: () => AppSnackBar.show(
                        context,
                        'Join Room ${room.kode} — fitur join menyusul.',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRooms() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.space12),
      child: EmptyStateView(
        icon: Icons.meeting_room_outlined,
        message: 'Belum ada room untuk kuis ini.',
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

  /// Label, warna teks, dan warna latar dari satu palet status bersama.
  ({String label, Color color, Color bg}) _statusInfo(String status) {
    final palette = QuizStatus.palette(status);
    return (
      label: QuizStatus.labelOf(status),
      color: palette.fg,
      bg: palette.bg,
    );
  }
}
