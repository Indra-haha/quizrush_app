import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/quiz.dart';
import '../../models/room.dart';
import '../../services/quiz_feed.dart';
import '../../services/quiz_index.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_pill_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quarantine_card.dart';
import '../../widgets/room_card.dart';
import '../../widgets/status_filter_row.dart';
import '../login_redirect.dart';
import 'create_room_sheet.dart';
import 'detail_room_page.dart';
import 'quiz_test_page.dart';
import 'rooms_page.dart';

const _statusFilters = ['waiting', 'open', 'in-Game', 'ended'];

class MyQuizPage extends StatefulWidget {
  final QuizIndex index;

  const MyQuizPage({super.key, required this.index});

  @override
  State<MyQuizPage> createState() => _MyQuizPageState();
}

class _MyQuizPageState extends State<MyQuizPage> {
  String _selectedStatus = 'waiting';
  late QuizIndex _index = widget.index;
  bool _syncing = false;

  List<({Quizes quiz, RoomSummary room})> _roomsFor(String status) {
    final entries = <({Quizes quiz, RoomSummary room})>[
      for (final quiz in _index.all)
        for (final room in quiz.rooms)
          if (room.status == status) (quiz: quiz, room: room),
    ];
    entries.sort((a, b) {
      final t = parseTimeOrEpoch(a.room.createdAt);
      final o = parseTimeOrEpoch(b.room.createdAt);
      return o.compareTo(t);
    });
    return entries;
  }

  Future<void> _openRooms(Quizes quiz) async {
    final result = await Navigator.of(context).push<PublishResult>(
      MaterialPageRoute<PublishResult>(
        builder: (_) => RoomsPage(quizId: quiz.id),
      ),
    );
    if (mounted && result != null) {
      setState(() => _selectedStatus = result.previous);
      AppSnackBar.show(context, 'Status room menjadi ${result.next}.');
      await _sync();
    }
  }

  Future<void> _testRoom(Quizes quiz, RoomSummary room) async {
    final result = await Navigator.of(context).push<PublishResult>(
      MaterialPageRoute<PublishResult>(
        builder: (_) => QuizTestPage(quiz: quiz),
      ),
    );
    if (mounted && result != null) {
      setState(() => _selectedStatus = result.previous);
      AppSnackBar.show(context, 'Status room menjadi ${result.next}.');
    }
  }

  Future<void> _openRoomDetail(Quizes quiz, RoomSummary room) async {
    final result = await Navigator.of(context).push<PublishResult>(
      MaterialPageRoute<PublishResult>(
        builder: (_) => RoomDetailPage(quizId: quiz.id, room: room),
      ),
    );
    if (mounted && result != null) {
      setState(() => _selectedStatus = result.previous);
      AppSnackBar.show(context, 'Status room menjadi ${result.next}.');
    }
    if (mounted) await _sync();
  }

  Future<void> _openCreateRoom() async {
    final room = await showCreateRoomSheet(context, _index.group('quarantine'));
    if (room == null || !mounted) return;
    await _showKodeDialog(room);
    await _sync();
  }

  Future<void> _showKodeDialog(Room room) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Room Dibuat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kode Room',
              style: AppTextStyles.statLabelOnPrimary.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Text(room.kode, style: AppTextStyles.code),
            const SizedBox(height: AppSpacing.space8),
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: room.kode));
                AppSnackBar.show(
                  dialogContext,
                  'Kode room disalin.',
                  duration: const Duration(seconds: 1),
                );
              },
              icon: const Icon(Icons.copy, size: AppIconSize.sm),
              label: const Text('Salin'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Server hanya dihubungi lewat tombol refresh atau setelah ada mutasi
  /// (publish status, create room).
  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);

    final result = await QuizFeed.syncMine();
    if (!mounted) return;

    if (result.needsAuth) {
      LoginRedirect.go(context);
      return;
    }

    final index = result.index;
    if (index != null) {
      setState(() {
        _syncing = false;
        _index = index;
      });
      return;
    }
    setState(() => _syncing = false);
    AppSnackBar.error(context, result.error ?? 'Gagal memuat ulang data.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBarWithActions(
        title: 'Quiz Saya',
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dari server',
            onPressed: _syncing ? null : _sync,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: AppPillButton(
        label: 'Create Room',
        icon: Icons.add,
        onPressed: _openCreateRoom,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildBody() {
    if (_index.isEmpty) return _buildEmpty();

    return ListView(
      padding: const EdgeInsets.only(
        left: AppSpacing.space9,
        right: AppSpacing.space9,
        top: AppSpacing.space8,
        bottom: AppSpacing.scrollClearance,
      ),
      children: [
        if (_index.group('quarantine').isNotEmpty) ...[
          for (final quiz in _index.group('quarantine'))
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space6),
              child: QuarantineCard(quiz: quiz, onTap: () => _openRooms(quiz)),
            ),
          const SizedBox(height: AppSpacing.space6),
        ],
        StatusFilterRow(
          statuses: _statusFilters,
          selected: _selectedStatus,
          onChanged: (status) => setState(() => _selectedStatus = status),
        ),
        const SizedBox(height: AppSpacing.space6),
        _buildRoomList(_selectedStatus),
      ],
    );
  }

  Widget _buildRoomList(String status) {
    final entries = _roomsFor(status);

    if (entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space14),
        child: EmptyStateView(
          icon: Icons.meeting_room_outlined,
          message: 'Tidak ada room dengan status "$status".',
        ),
      );
    }

    return Column(
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space6),
            child: RoomCard(
              quiz: entry.quiz,
              room: entry.room,
              onTap: () => _openRoomDetail(entry.quiz, entry.room),
              onTestPressed: () => _testRoom(entry.quiz, entry.room),
            ),
          ),
      ],
    );
  }

  Widget _buildEmpty() {
    return const EmptyStateView(
      icon: Icons.quiz_outlined,
      message: 'Belum ada quiz untukmu.',
    );
  }
}
