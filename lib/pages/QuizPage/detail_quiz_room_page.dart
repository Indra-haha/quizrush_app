import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/quiz.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_status.dart';
import '../../utils/format.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_snackbar.dart';
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

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6063EE), Color(0xFF4648D4)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x144648D4),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [_heroStatusPill(info.color)]),
            const SizedBox(height: 16),
            Text(
              quiz.title,
              style: AppTextStyles.heading1.copyWith(color: Colors.white),
            ),
            if (quiz.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                quiz.description,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ],
            const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _statTile(
                      icon: Icons.timer_outlined,
                      value: formatDuration(totalDuration(quiz)),
                      label: 'Durasi',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statTile(
                      icon: Icons.list_alt,
                      value: '${quiz.questions.length}',
                      label: 'Pertanyaan',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _statTile(
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
      ),
    );
  }

  Widget _heroStatusPill(Color dotColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            _statusInfo(_quizStatus(quiz)).label,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              height: 1.33,
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE1E0FF),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                '$count Room',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF07006C),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
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
            color: Color(0x0F000000),
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
            _focusBadge(),
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
              color: const Color(0xFFF0F3FF),
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
                    child: FilledButton(
                      onPressed: () => AppSnackBar.show(
                        context,
                        'Join Room ${room.kode} — fitur join menyusul.',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                      ),
                      child: Text(
                        'Masuk',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.43,
                        ),
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

  Widget _focusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE1E0FF),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.pin, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            'Room dari PIN yang kamu masukkan',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF07006C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.33,
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
        iconColor: AppColors.neutral,
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

  ({String label, Color color, Color bg}) _statusInfo(String status) {
    return (
      label: QuizStatus.labelOf(status),
      color: _statusColor(status),
      bg: _statusBg(status),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFF6B38D4);
      case 'in-Game':
        return AppColors.warningDark;
      case 'ended':
        return AppColors.neutralDark;
      case 'waiting':
        return AppColors.muted;
      default:
        return AppColors.brandDeep;
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'open':
        return const Color(0xFFE9DDFF);
      case 'in-Game':
        return AppColors.warningBg;
      case 'ended':
        return AppColors.neutralBg;
      case 'waiting':
        return AppColors.softBg;
      default:
        return const Color(0xFFE1E0FF);
    }
  }
}
