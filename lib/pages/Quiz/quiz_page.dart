import 'dart:async';

import 'package:flutter/material.dart';

import '../../helpers/pin.dart';
import '../../helpers/room_launcher.dart';
import '../../models/quiz.dart';
import '../../models/room.dart';
import '../../services/active_room_service.dart';
import '../../services/api/api_client.dart';
import '../../services/quiz_feed.dart';
import '../../services/quiz_index.dart';
import '../../theme/app_theme.dart';
import '../../widgets/active_room_banner.dart';
import '../../widgets/app_options_select.dart';
import '../../widgets/app_pill_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/cache_info_bar.dart';
import '../../widgets/points_indicator.dart';
import '../../widgets/quiz_results_list.dart';
import '../../widgets/quiz_search_field.dart';
import '../../widgets/section_header.dart';
import '../login_redirect.dart';
import 'detail_quiz_room_page.dart';
import 'enter_pin_page.dart';

class QuizPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const QuizPage({super.key, this.user});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const _statuses = ['open', 'in-Game', 'ended'];

  QuizIndex? _index;
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  String _selectedStatus = 'open';
  bool _notFound = false;
  bool _reentering = false;
  final _searchController = TextEditingController();
  Timer? _notFoundTimer;

  Room? get _activeRoom => ActiveRoomService.instance.room;

  /// Jumlah digit PIN yang sudah diketik (1-5), atau null kalau kolom pencarian
  /// tidak berisi PIN sebagian: kosong, ada huruf, atau sudah 6 digit.
  int? get _pinProgress => Pin.progress(_searchController.text);

  @override
  void initState() {
    super.initState();
    ActiveRoomService.instance.addListener(_onActiveRoomChanged);
    _load();
  }

  @override
  void dispose() {
    ActiveRoomService.instance.removeListener(_onActiveRoomChanged);
    _notFoundTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onActiveRoomChanged() {
    if (mounted) setState(() {});
  }

  /// Daftar quiz dibaca dari cache lokal; server hanya dihubungi kalau cache
  /// belum pernah diisi.
  Future<void> _load() => _run(QuizFeed.loadAll);

  /// Dipakai oleh tombol refresh, tombol "Muat dari Server", dan setelah ada
  /// data yang berubah di server.
  Future<void> _sync() => _run(QuizFeed.syncAll);

  Future<void> _run(Future<QuizFeedResult> Function() feed) async {
    if (_syncing) return;
    setState(() {
      _loading = true;
      _syncing = true;
      _error = null;
    });

    final result = await feed();
    if (!mounted) return;

    if (result.needsAuth) {
      LoginRedirect.go(context);
      return;
    }

    setState(() {
      _index = result.index ?? _index;
      _error = result.error;
      _loading = false;
      _syncing = false;
      _ensureSelectedStatus();
    });
  }

  void _ensureSelectedStatus() {
    final index = _index;
    if (index == null) return;
    if (index.group(_selectedStatus).isNotEmpty) return;
    for (final status in _statuses) {
      if (index.group(status).isNotEmpty) {
        _selectedStatus = status;
        return;
      }
    }
  }

  List<Quizes> get _selectedQuizzes {
    final index = _index;
    if (index == null) return const [];

    final quizzes = index.group(_selectedStatus);
    final query = _searchController.text;
    if (query.trim().isEmpty) return quizzes;

    return quizzes.where((quiz) => index.matches(quiz, query)).toList();
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

  /// Cari room di index cache, lalu langsung arahkan ke detail kuisnya.
  /// Kalau tidak ada, tampilkan state "room tidak ditemukan" selama tiga detik
  /// lalu kembalikan user ke daftar quiz seperti biasa.
  void _openRoomByPin(String kode) {
    final found = _index?.findRoomByKode(kode);
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            DetailQuizRoomPage(quiz: found.quiz, focusKode: found.room.kode),
      ),
    );
  }

  void _openRooms(Quizes quiz) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailQuizRoomPage(quiz: quiz)));
  }

  /// Buka halaman input PIN untuk memverifikasi kode room ke
  /// `POST /api/rooms/verify` lalu masuk ke ruang tunggu (lobby).
  void _openEnterPin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const EnterPinPage()));
  }

  /// Masuk kembali ke room terakhir tanpa mengetik PIN: verifikasi ulang kode
  /// yang tersimpan lewat `RoomLauncher` untuk token yang masih segar. Room yang
  /// sudah hilang (404) otomatis dibersihkan.
  Future<void> _reenterRoom() async {
    final room = _activeRoom;
    if (room == null || _reentering) return;

    setState(() => _reentering = true);
    try {
      await RoomLauncher.enter(context: context, pin: room.kode);
    } on ApiException catch (e) {
      if (!mounted) return;
      _handleReenteringError(
        statusCode: e.statusCode,
        message: e.message.isNotEmpty ? e.message : 'Gagal masuk ke room.',
      );
      return;
    } catch (_) {
      if (!mounted) return;
      _finishReentering();

      AppSnackBar.error(context, 'Tidak bisa terhubung ke server. Coba lagi.');
      return;
    }
    if (!mounted) return;
    _finishReentering();
  }

  void _finishReentering() {
    setState(() => _reentering = false);
  }

  void _handleReenteringError({
    required int statusCode,
    required String message,
  }) {
    _finishReentering();
    if (statusCode == 404) {
      ActiveRoomService.instance.clear();
      AppSnackBar.error(context, 'Room tidak ditemukan lagi.');
    } else {
      AppSnackBar.error(context, message);
    }
  }

  void _forgetActiveRoom() {
    FocusScope.of(context).unfocus();
    ActiveRoomService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      floatingActionButton: AppPillButton(
        label: 'Masukkan PIN',
        icon: Icons.pin_outlined,
        onPressed: _openEnterPin,
      ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space9,
                AppSpacing.space8,
                AppSpacing.space9,
                AppSpacing.space6,
              ),
              child: Row(
                children: [
                  const Expanded(child: SectionHeader(title: 'Quiz')),
                  const PointsIndicator(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space9,
              ),
              child: QuizSearchField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onRefresh: _sync,
                syncing: _syncing,
                loading: _loading,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space9,
              ),
              child: CacheInfoBar(
                savedAt: _index?.savedAt,
                pinProgress: _pinProgress,
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space9,
              ),
              child: ListOptions(
                optionLists: _statuses,
                selectedOption: _selectedStatus,
                onSelectedChange: (status) => setState(() => _selectedStatus = status),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            if (_activeRoom != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space9,
                  0,
                  AppSpacing.space9,
                  AppSpacing.space4,
                ),
                child: ActiveRoomBanner(
                  room: _activeRoom!,
                  loading: _reentering,
                  onEnter: _reenterRoom,
                  onDismiss: _forgetActiveRoom,
                ),
              ),
            ],
            Expanded(
              child: QuizResultsList(
                loading: _loading,
                error: _error,
                notFound: _notFound,
                pinProgress: _pinProgress,
                quizzes: _selectedQuizzes,
                query: _searchController.text.trim(),
                onRetry: _sync,
                onTapQuiz: _openRooms,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
