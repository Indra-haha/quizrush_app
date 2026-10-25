import 'dart:async';

import 'package:flutter/material.dart';

import '../../helpers/format.dart';
import '../../helpers/pin.dart';
import '../../models/quiz.dart';
import '../../models/room.dart';
import '../../services/quiz_feed.dart';
import '../../services/quiz_index.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_pill_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/quiz_group_card.dart';
import '../../widgets/quiz_search_field.dart';
import '../../widgets/quarantine_card.dart';
import '../../widgets/room_code_dialog.dart';
import '../../widgets/status_filter_row.dart';
import '../login_redirect.dart';
import 'create_room_sheet.dart';
import 'detail_room_page.dart';
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
  bool _saving = false;
  bool _notFound = false;
  final _searchController = TextEditingController();
  Timer? _notFoundTimer;

  /// Jumlah digit PIN yang sudah diketik (1-5), atau null kalau kolom pencarian
  /// tidak berisi PIN sebagian: kosong, ada huruf, atau sudah 6 digit.
  int? get _pinProgress => Pin.progress(_searchController.text);

  @override
  void dispose() {
    _notFoundTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Quiz yang punya minimal satu room berstatus [status], sudah difilter
  /// lewat kolom pencarian. Tiap entri memuat daftar room yang cocok, diurutkan
  /// dari yang terbaru; urutan kartu mengikuti room terbarunya.
  List<({Quizes quiz, List<RoomSummary> rooms})> _groupedQuizzes(
    String status,
  ) {
    final query = _searchController.text.trim();
    final groups = <({Quizes quiz, List<RoomSummary> rooms})>[];

    for (final quiz in _index.all) {
      if (query.isNotEmpty && !_index.matches(quiz, query)) continue;
      final rooms = <RoomSummary>[
        for (final room in quiz.rooms)
          if (room.status == status) room,
      ];
      if (rooms.isEmpty) continue;
      rooms.sort(
        (a, b) => parseTimeOrEpoch(
          b.createdAt,
        ).compareTo(parseTimeOrEpoch(a.createdAt)),
      );
      groups.add((quiz: quiz, rooms: rooms));
    }

    groups.sort(
      (a, b) => parseTimeOrEpoch(
        b.rooms.first.createdAt,
      ).compareTo(parseTimeOrEpoch(a.rooms.first.createdAt)),
    );
    return groups;
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
    await showRoomCodeDialog(context, room.kode);
    await _sync();
  }

  void _onSearchChanged(String value) {
    _notFoundTimer?.cancel();
    final query = value.trim();
    if (Pin.isComplete(query)) {
      _openRoomByPin(query);
      return;
    }
    setState(() => _notFound = false);
  }

  /// Cari room di index cache, lalu langsung buka detail room-nya. Kalau tidak
  /// ada, tampilkan state "room tidak ditemukan" selama tiga detik lalu
  /// kembalikan user ke daftar seperti biasa.
  void _openRoomByPin(String kode) {
    final found = _index.findRoomByKode(kode);
    if (found == null) {
      setState(() => _notFound = true);
      _notFoundTimer?.cancel();
      _notFoundTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        _searchController.clear();
        setState(() => _notFound = false);
      });
      return;
    }

    _searchController.clear();
    setState(() => _notFound = false);
    FocusScope.of(context).unfocus();
    _openRoomDetail(found.quiz, found.room);
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
      backgroundColor: AppColors.quizCanvas,
      appBar: AppHeaderBarWithActions(
        title: 'Quiz Saya',
        titleStyle: CreateQuizTextStyles.headerTitle,
        backgroundColor: CreateQuizPageStyles.headerBackground,
        elevation: CreateQuizPageStyles.headerElevation,
        shadowColor: CreateQuizPageStyles.headerShadowColor,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back),
        )),
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
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _sync,
      child: _buildList(),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space8,
        AppSpacing.space8,
        AppSpacing.space8,
        AppSpacing.scrollClearance,
      ),
      children: [
        QuizSearchField(
          controller: _searchController,
          onChanged: _onSearchChanged,
        ),
        const SizedBox(height: AppSpacing.space4),
        StatusFilterRow(
          statuses: _statusFilters,
          selected: _selectedStatus,
          onChanged: (status) => setState(() => _selectedStatus = status),
        ),
        const SizedBox(height: AppSpacing.space4),
        ..._buildContent(),
      ],
    );
  }

  List<Widget> _buildContent() {
    if (_notFound) return [_padded(const EmptyStateView.notFound())];
    if (_pinProgress != null) {
      return [_padded(EmptyStateView.searching(_pinProgress!))];
    }

    final query = _searchController.text.trim();
    final children = <Widget>[];

    if (_index.isEmpty) {
      children.add(
        _padded(
          const EmptyStateView(
            icon: Icons.quiz_outlined,
            message: 'Belum ada quiz untukmu.',
          ),
        ),
      );
      return children;
    }

    final quarantines = _index.group('quarantine');
    if (quarantines.isNotEmpty) {
      for (final quiz in quarantines) {
        children.add(
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space6),
            child: QuarantineCard(quiz: quiz, onTap: () => _openRooms(quiz)),
          ),
        );
      }
      children.add(const SizedBox(height: AppSpacing.space6));
    }

    final groups = _groupedQuizzes(_selectedStatus);
    if (groups.isEmpty) {
      children.add(
        _padded(
          query.isEmpty
              ? EmptyStateView(
                  icon: Icons.meeting_room_outlined,
                  message: 'Tidak ada room dengan status "$_selectedStatus".',
                )
              : EmptyStateView.noResult(query),
        ),
      );
      return children;
    }

    for (final group in groups) {
      children.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space6),
          child: QuizGroupCard(
            quiz: group.quiz,
            rooms: group.rooms,
            onTapHeader: () => _openRooms(group.quiz),
            onTapRoom: (room) => _openRoomDetail(group.quiz, room),
          ),
        ),
      );
    }
    return children;
  }

  Widget _padded(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space14),
      child: child,
    );
  }
}
