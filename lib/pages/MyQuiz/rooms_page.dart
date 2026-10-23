import 'package:flutter/material.dart';

import '../../models/quiz.dart';
import '../../models/room.dart' show PublishResult;
import '../../services/quiz_feed.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/room_list_tile.dart';
import '../login_redirect.dart';
import 'detail_room_page.dart' show RoomDetailPage;

/// Daftar room milik satu kuis. Data dibaca dari cache; tombol refresh yang
/// mengisi ulang cache dari server.
class RoomsPage extends StatefulWidget {
  final String quizId;

  const RoomsPage({super.key, required this.quizId});

  @override
  State<RoomsPage> createState() => _RoomsPageState();
}

class _RoomsPageState extends State<RoomsPage> {
  Quizes? _quiz;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Cache dulu; kalau belum pernah diisi, baru hubungi server.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await QuizFeed.readCachedQuizById(widget.quizId);
    if (!mounted) return;
    if (cached == null) {
      await _sync();
      return;
    }
    setState(() {
      _quiz = cached;
      _loading = false;
    });
  }

  Future<void> _sync() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await QuizFeed.syncMine();
    if (!mounted) return;

    if (result.needsAuth) {
      LoginRedirect.go(context);
      return;
    }

    final index = result.index;
    setState(() {
      _quiz = index?.quizById(widget.quizId);
      _error = result.error;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = _quiz?.title;
    return Scaffold(
      appBar: AppHeaderBarWithActions(
        title: title == null || title.isEmpty ? 'Rooms' : title,
        actions: [
          IconButton(
            tooltip: 'Refresh dari server',
            onPressed: _loading ? null : _sync,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final quiz = _quiz;

    if (quiz == null && _loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (quiz == null && _error != null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    if (quiz == null) {
      return const EmptyStateView(
        icon: Icons.quiz_outlined,
        message: 'Quiz tidak ditemukan.',
      );
    }

    final rooms = quiz.rooms;

    if (rooms.isEmpty) {
      return const EmptyStateView(
        icon: Icons.meeting_room_outlined,
        message: 'Belum ada room untuk quiz ini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.space8),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space4),
      itemBuilder: (context, index) {
        final room = rooms[index];
        return RoomListTile(
          room: room,
          index: index,
          quizTitle: quiz.title,
          onTap: () => _openRoom(room),
        );
      },
    );
  }

  Future<void> _openRoom(RoomSummary room) async {
    final navigator = Navigator.of(context);
    final result = await navigator.push<PublishResult>(
      MaterialPageRoute<PublishResult>(
        builder: (_) => RoomDetailPage(quizId: widget.quizId, room: room),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      _load();
    } else {
      navigator.pop(result);
    }
  }
}
