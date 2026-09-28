import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/quiz.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/quiz_cache_service.dart';
import '../services/quiz_index.dart';
import '../services/quiz_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/app_header_bar_with_actions.dart';
import '../widgets/app_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/quiz_card.dart';
import '../widgets/section_header.dart';
import 'MyQuizPage/create_quiz_page.dart';
import 'MyQuizPage/my_quiz_page.dart';
import 'QuizPage/detail_quiz_room_page.dart' show DetailQuizRoomPage;
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _user;
  bool _loggingOut = false;
  QuizIndex? _index;
  bool _loading = true;
  bool _syncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
    _load();
  }

  Future<void> _loadUser() async {
    final user = await SessionService.instance.getUser();
    if (user != null && mounted) {
      setState(() => _user = user);
    }
  }

  /// Daftar quiz dibaca dari cache lokal; server hanya dihubungi kalau cache
  /// belum pernah diisi.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await QuizCacheService.instance.readMine();
    if (!mounted) return;

    if (cached == null) {
      await _sync();
      return;
    }

    setState(() {
      _index = QuizIndex.fromCache(cached);
      _loading = false;
    });
  }

  /// Dipakai oleh tombol refresh dan setelah quiz/room dibuat.
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
      final data = await QuizService.instance.getMyQuizzes(token);
      final cache = await QuizCacheService.instance.saveMyQuizzes(data);
      if (!mounted) return;
      setState(() {
        _index = QuizIndex.fromCache(cache);
        _loading = false;
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
      debugPrint('Quiz sync error: $e');
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

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    final token = await SessionService.instance.getToken();
    try {
      if (token != null) {
        await AuthService.instance.logout(token);
      }
    } catch (_) {
      // Backend tidak terjangkau; session lokal tetap dihapus.
    }
    await SessionService.instance.clear();
    await QuizCacheService.instance.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  void _openRooms(Quizes quiz) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailQuizRoomPage(quiz: quiz)));
  }

  void _openAll() {
    final index = _index;
    if (index == null) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => MyQuizPage(index: index)));
  }

  ({String status, Quizes quiz})? _currentSection() {
    const priority = ['waiting', 'open', 'in-Game', 'ended', 'quarantine'];
    final index = _index;
    if (index == null) return null;

    for (final status in priority) {
      final quizzes = index.group(status);
      if (quizzes.isEmpty) continue;
      final sorted = [...quizzes]
        ..sort((a, b) => _latestTime(b).compareTo(_latestTime(a)));
      return (status: status, quiz: sorted.first);
    }
    return null;
  }

  DateTime _latestTime(Quizes quiz) {
    var latest = parseTimeOrEpoch(quiz.createdAt);
    for (final room in quiz.rooms) {
      final time = parseTimeOrEpoch(room.createdAt);
      if (time.isAfter(latest)) latest = time;
    }
    return latest;
  }

  Future<void> _onCreateQuiz() async {
    final created = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const CreateQuizPage()));
    if (created != true || !mounted) return;

    await _sync();
    if (!mounted) return;
    AppSnackBar.success(context, 'Quiz berhasil dibuat.');
    _openAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderBarWithActions(
        actions: [
          IconButton(
            tooltip: 'Refresh dari server',
            onPressed: _loading ? null : _sync,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: _loggingOut ? null : _logout,
            icon: _loggingOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: AppPillButton(
        label: 'Create Quiz',
        icon: Icons.add,
        onPressed: _onCreateQuiz,
      ),
    );
  }

  Widget _buildBody() {
    final section = _currentSection();

    return ListView(
      padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 96),
      children: [
        _buildGreeting(),
        const SizedBox(height: 16),
        _buildStats(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _buildError()
        else if (section == null)
          _buildEmpty()
        else ...[
          const SizedBox(height: 16),
          SectionHeader(title: 'Quiz saya', onSeeAll: _openAll),
          const SizedBox(height: 16),
          QuizCard(quiz: section.quiz, onTap: () => _openRooms(section.quiz)),
        ],
        if (!_loading && _error == null) _buildCacheInfo(),
      ],
    );
  }

  Widget _buildCacheInfo() {
    final savedAt = _index?.savedAt;
    if (savedAt == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        children: [
          const Icon(
            Icons.offline_bolt_outlined,
            size: 12,
            color: AppColors.neutral,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Daftar ini dari cache perangkat. Terakhir diperbarui '
              '${relativeTime(savedAt.toIso8601String())}.',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.neutral,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting() {
    final nama = (_user?['nama'] as String?) ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang,',
          style: GoogleFonts.plusJakartaSans(
            color: AppColors.primary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 1.43,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          nama.isEmpty ? 'Halo! 👋' : 'Halo, $nama! 👋',
          style: GoogleFonts.montserrat(
            color: AppColors.ink,
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Total Main',
                value: '1.2k',
                icon: Icons.sports_esports,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                label: 'Rating Rata-rata',
                value: '4.8',
                icon: Icons.star,
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatCard(
                label: 'Host Aktif',
                value: '12',
                icon: Icons.person,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                label: 'Terakhir Update',
                value: _savedAtLabel(),
                icon: Icons.access_time,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _savedAtLabel() {
    final savedAt = _index?.savedAt;
    if (savedAt == null) return '-';
    return relativeTime(savedAt.toIso8601String());
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    bool highlight = false,
  }) {
    final fg = highlight ? AppColors.onHighlight : AppColors.ink;
    final subFg = highlight ? AppColors.onHighlight : AppColors.muted;

    return Container(
      width: double.infinity,
      height: 128,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? AppColors.highlight : AppColors.softBg,
        borderRadius: BorderRadius.circular(32),
        border: highlight ? null : Border.all(color: const Color(0x4CC7C4D7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: fg, size: 28),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: subFg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.montserrat(
                  color: fg,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1.33,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: ErrorStateView(
        message: _error!,
        onRetry: _sync,
        buttonColor: AppColors.highlight,
        messageStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: AppColors.muted,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48),
      child: EmptyStateView(
        icon: Icons.quiz_outlined,
        message: 'Belum ada quiz untukmu.',
      ),
    );
  }
}
