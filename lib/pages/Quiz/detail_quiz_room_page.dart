import 'package:flutter/material.dart';

import '../../helpers/room_launcher.dart';
import '../../models/quiz.dart';
import '../../services/active_room_service.dart';
import '../../services/api/api_client.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quiz_detail_hero.dart';
import '../../widgets/room_detail_card.dart';
import '../../widgets/room_list_header.dart';
import '../login_redirect.dart';

class DetailQuizRoomPage extends StatefulWidget {
  final Quizes quiz;
  final String? focusKode;

  const DetailQuizRoomPage({super.key, required this.quiz, this.focusKode});

  @override
  State<DetailQuizRoomPage> createState() => _DetailQuizRoomPageState();
}

class _DetailQuizRoomPageState extends State<DetailQuizRoomPage> {
  bool _joining = false;

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
    final rooms = widget.quiz.rooms
        .where((room) => room.status != 'waiting' || room.kode == widget.focusKode)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space8,
        AppSpacing.space9,
        AppSpacing.space12,
      ),
      children: [
        QuizDetailHero(quiz: widget.quiz),
        const SizedBox(height: AppSpacing.space10),
        RoomListHeader(count: rooms.length),
        const SizedBox(height: AppSpacing.space8),
        if (rooms.isEmpty) _emptyRooms(),
        for (var i = 0; i < rooms.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space8),
          RoomDetailCard(
            room: rooms[i],
            index: i,
            isFocused: rooms[i].kode == widget.focusKode && widget.focusKode != null,
            onJoin: _joining ? null : () => _joinRoom(context, rooms[i].kode),
          ),
        ],
        const SizedBox(height: AppSpacing.space10),
      ],
    );
  }

  Future<void> _joinRoom(BuildContext context, String pin) async {
    if (_joining) return;
    setState(() => _joining = true);
    try {
      await RoomLauncher.enter(context: context, pin: pin);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        await SessionService.instance.clear();
        ActiveRoomService.instance.clear();
        if (!context.mounted) return;
        LoginRedirect.go(context);
        return;
      }
      if (!context.mounted) return;
      AppSnackBar.error(
        context,
        e.message.isNotEmpty ? e.message : 'Gagal masuk ke room.',
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.error(context, 'Tidak bisa terhubung ke server. Coba lagi.');
    } finally {
      if (mounted) setState(() => _joining = false);
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
