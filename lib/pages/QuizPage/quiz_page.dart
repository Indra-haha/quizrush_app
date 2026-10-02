import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/quiz.dart';
import '../../services/quiz_feed.dart';
import '../../services/quiz_index.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cache_info_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/quiz_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_filter_row.dart';
import '../login_redirect.dart';
import 'detail_quiz_room_page.dart';

class QuizPage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const QuizPage({super.key, this.user});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  static const _statuses = ['open', 'in-Game', 'ended'];
  static final _pinPattern = RegExp(r'^\d{6}$');
  static final _partialPinPattern = RegExp(r'^\d{1,5}$');

  QuizIndex? _index;
  bool _loading = true;
  bool _syncing = false;
  String? _error;
  String _selectedStatus = 'open';
  bool _notFound = false;
  final _searchController = TextEditingController();
  Timer? _notFoundTimer;

  /// Jumlah digit PIN yang sudah diketik (1-5), atau null kalau kolom pencarian
  /// tidak berisi PIN sebagian: kosong, ada huruf, atau sudah 6 digit.
  int? get _pinProgress {
    final query = _searchController.text.trim();
    if (!_partialPinPattern.hasMatch(query)) return null;
    return query.length;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _notFoundTimer?.cancel();
    _searchController.dispose();
    super.dispose();
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
    if (_pinPattern.hasMatch(query)) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
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
              child: SectionHeader(title: 'Quiz'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space9,
              ),
              child: _buildSearchField(),
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
              child: StatusFilterRow(
                statuses: _statuses,
                selected: _selectedStatus,
                onChanged: (status) => setState(() => _selectedStatus = status),
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'Ketik judul kuis atau 6 digit PIN...',
        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.info),
        filled: true,
        fillColor: AppColors.textOnPrimary.withValues(alpha: 0.70),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space8,
          vertical: AppSpacing.space6,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: AppIconSize.sm,
          color: AppColors.info,
        ),
        suffixIcon: _syncing
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.space7),
                child: SizedBox(
                  width: AppSpacing.space7,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Refresh dari server',
                onPressed: _loading ? null : _sync,
                icon: const Icon(
                  Icons.refresh,
                  size: AppIconSize.sm,
                  color: AppColors.info,
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return ErrorStateView(message: _error!, onRetry: _sync);
    }

    if (_notFound) return const EmptyStateView.notFound();
    final progress = _pinProgress;
    if (progress != null) return EmptyStateView.searching(progress);

    final quizzes = _selectedQuizzes;

    if (quizzes.isEmpty) {
      final query = _searchController.text.trim();
      if (query.isEmpty) return const EmptyStateView.empty();
      return EmptyStateView.noResult(query);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space4,
        AppSpacing.space9,
        AppSpacing.scrollClearance,
      ),
      children: [
        for (var i = 0; i < quizzes.length; i++) ...[
          if (i > 0) const SizedBox(height: AppSpacing.space9),
          QuizCard(quiz: quizzes[i], onTap: () => _openRooms(quizzes[i])),
        ],
      ],
    );
  }
}
