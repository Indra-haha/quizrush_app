import 'package:flutter/material.dart';

import '../../helpers/room_launcher.dart';
import '../../models/quiz.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quiz_detail_hero.dart';
import '../../widgets/room_detail_card.dart';
import '../../widgets/room_list_header.dart';

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
        QuizDetailHero(quiz: quiz),
        const SizedBox(height: AppSpacing.space10),
        RoomListHeader(count: rooms.length),
        const SizedBox(height: AppSpacing.space8),
        if (rooms.isEmpty) _emptyRooms(),
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space8),
          RoomDetailCard(
            room: rooms[i],
            index: i,
            isFocused: rooms[i].kode == focusKode && focusKode != null,
            onJoin: () => _joinRoom(context, rooms[i].kode),
          ),
        ],
        const SizedBox(height: AppSpacing.space10),
      ],
    );
  }

  Future<void> _joinRoom(BuildContext context, String pin) async {
    try {
      await RoomLauncher.enter(context: context, pin: pin);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      AppSnackBar.error(
        context,
        e.message.isNotEmpty ? e.message : 'Gagal masuk ke room.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Tidak bisa terhubung ke server. Coba lagi.');
    }
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
}
