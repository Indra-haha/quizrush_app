import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/quiz.dart';
import '../../services/api_client.dart';
import '../../services/quiz_cache_service.dart';
import '../../services/quiz_index.dart';
import '../../services/quiz_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/cache_info_bar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/quiz_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/status_filter_row.dart';
import '../login_page.dart';
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
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await QuizCacheService.instance.readAll();
    if (!mounted) return;

    if (cached == null) {
      await _sync();
      return;
    }

    setState(() {
      _index = QuizIndex.fromCache(cached);
      _loading = false;
      _ensureSelectedStatus();
    });
  }

  /// Dipakai oleh tombol refresh, tombol "Muat dari Server", dan setelah ada
  /// data yang berubah di server.
  Future<void> _sync() async {
    if (_syncing) return;
    setState(() {
      _syncing = true;
      _loading = true;
      _error = null;
    });

    final token = await SessionService.instance.getToken();
    if (token == null) {
      _syncing = false;
      _goToLogin();
      return;
    }

    try {
      final data = await QuizService.instance.getQuizzes(token);
      final cache = await QuizCacheService.instance.saveAllQuizzes(data);
      if (!mounted) return;
      setState(() {
        _index = QuizIndex.fromCache(cache);
        _loading = false;
        _ensureSelectedStatus();
      });
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await SessionService.instance.clear();
        _goToLogin();
        return;
      }
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Quizzes sync error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server. ($e)';
        _loading = false;
      });
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
      backgroundColor: AppColors.cardBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: SectionHeader(title: 'Quiz'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSearchField(),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CacheInfoBar(
                savedAt: _index?.savedAt,
                pinProgress: _pinProgress,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatusFilterRow(
                statuses: _statuses,
                selected: _selectedStatus,
                onChanged: (status) =>
                    setState(() => _selectedStatus = status),
              ),
            ),
            const SizedBox(height: 8),
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
      style: GoogleFonts.plusJakartaSans(
        color: AppColors.ink,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: 'Ketik judul kuis atau 6 digit PIN...',
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.neutral,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.70),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        prefixIcon: const Icon(
          Icons.search,
          size: 16,
          color: AppColors.neutral,
        ),
        suffixIcon: _syncing
            ? const Padding(
                padding: EdgeInsets.all(14),
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : IconButton(
                tooltip: 'Refresh dari server',
                onPressed: _loading ? null : _sync,
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: AppColors.neutral,
                ),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutralBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutralBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutralBorder),
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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 112),
      children: [
        for (var i = 0; i < quizzes.length; i++) ...[
          if (i > 0) const SizedBox(height: 20),
          QuizCard(quiz: quizzes[i], onTap: () => _openRooms(quizzes[i])),
        ],
      ],
    );
  }
}
