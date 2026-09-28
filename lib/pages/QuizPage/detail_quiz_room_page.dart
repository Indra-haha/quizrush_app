import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_status.dart';
import '../../utils/format.dart';
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

  const DetailQuizRoomPage({
    super.key,
    required this.quiz,
    this.focusKode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardBg,
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
        .where(
          (room) => room.status != 'waiting' || room.kode == focusKode,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _heroCard(quiz),
        const SizedBox(height: 24),
        _roomSectionHeader(rooms.length),
        const SizedBox(height: 16),
        if (rooms.isEmpty) _emptyRooms(),
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _roomCard(context, quiz, rooms[i], i),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _heroCard(Quizes quiz) {
    final status = _quizStatus(quiz);
    final info = _statusInfo(status);

    return AppHeroCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                text: info.label,
                background: Colors.white.withValues(alpha: 0.90),
                foreground: AppColors.primary,
                dot: info.color,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            quiz.title,
            style: AppTextStyles.heading1.copyWith(color: Colors.white),
          ),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            AppHeroSubtitle(quiz.description, fontSize: 14),
          ],
          const SizedBox(height: 20),
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
                const SizedBox(width: 8),
                Expanded(
                  child: AppStatTile.stacked(
                    icon: Icons.list_alt,
                    value: '${quiz.questions.length}',
                    label: 'Pertanyaan',
                  ),
                ),
                const SizedBox(width: 8),
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
            Text(
              'Daftar Room',
              style: AppTextStyles.heading1.copyWith(fontSize: 24),
            ),
            const SizedBox(width: 8),
            AppPill(
              text: '$count Room',
              background: AppColors.softLavender,
              foreground: AppColors.inkStrong,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ],
        ),
        const SizedBox(height: 4),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: isFocused
            ? Border.all(color: AppColors.primary, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowHairline,
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: info.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.33,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isFocused) ...[
            const AppPill(
              text: 'Room dari PIN yang kamu masukkan',
              background: AppColors.softLavender,
              foreground: AppColors.inkStrong,
              icon: Icons.pin,
            ),
            const SizedBox(height: 12),
          ],
          Text(
            room.judul,
            style: GoogleFonts.montserrat(
              color: AppColors.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.33,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.muted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.50,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
            decoration: BoxDecoration(
              color: AppColors.optionBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIN SERVER', style: AppTextStyles.bodyMeta),
                    const SizedBox(height: 2),
                    Text(
                      formatKode(room.kode),
                      style: GoogleFonts.montserrat(
                        color: AppColors.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.33,
                        letterSpacing: 1.20,
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
                      padding: const EdgeInsets.symmetric(horizontal: 24),
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
      padding: EdgeInsets.symmetric(vertical: 32),
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
