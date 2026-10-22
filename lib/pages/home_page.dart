import 'package:flutter/material.dart';

import '../models/quiz.dart';
import '../services/quiz_feed.dart';
import '../services/quiz_index.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../helpers/format.dart';
import '../widgets/app_header_bar_with_actions.dart';
import '../widgets/app_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/cache_info_bar.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/error_state_view.dart';
import '../widgets/home_greeting.dart';
import '../widgets/home_stat_card.dart';
import '../widgets/points_indicator.dart';
import '../widgets/quiz_card.dart';
import '../widgets/section_header.dart';
import 'MyQuizPage/create_quiz_page.dart';
import 'MyQuizPage/my_quiz_page.dart';
import 'QuizPage/detail_quiz_room_page.dart' show DetailQuizRoomPage;
import 'login_redirect.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const HomePage({super.key, this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, dynamic>? _user;
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
  Future<void> _load() => _run(QuizFeed.loadMine);

  /// Dipakai oleh tombol refresh dan setelah quiz/room dibuat.
  Future<void> _sync() => _run(QuizFeed.syncMine);

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
    });
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
      backgroundColor: AppColors.pageBase,
      appBar: AppHeaderBarWithActions(
        actions: const [PointsIndicator(style: PointsIndicatorStyle.home)],
      ),
      body: _buildBody(),
      floatingActionButton: AppPillButton(
        label: 'Create Quiz',
        onPressed: _onCreateQuiz,
      ),
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
    final section = _currentSection();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.space8,
        left: AppSpacing.space9,
        right: AppSpacing.space9,
        bottom: AppSpacing.fabClearance,
      ),
      children: [
        HomeGreeting(name: (_user?['nama'] as String?) ?? ''),
        const SizedBox(height: AppSpacing.space8),
        _buildStats(),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space14),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _buildError()
        else if (section == null)
          _buildEmpty()
        else ...[
          const SizedBox(height: AppSpacing.space8),
          SectionHeader(title: 'Quiz Saya', onSeeAll: _openAll),
          const SizedBox(height: AppSpacing.space8),
          QuizCard(
            quiz: section.quiz,
            style: QuizCardStyle.home,
            onTap: () => _openRooms(section.quiz),
          ),
        ],
        if (!_loading && _error == null) _buildCacheInfo(),
      ],
    );
  }

  Widget _buildCacheInfo() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space9),
      child: CacheInfoBar(
        savedAt: _index?.savedAt,
        savedAtLabel: 'Daftar ini dari cache perangkat. Terakhir diperbarui',
      ),
    );
  }

  String _savedAtLabel() {
    final savedAt = _index?.savedAt;
    if (savedAt == null) return '-';
    return relativeTime(savedAt.toIso8601String());
  }

  Widget _buildStats() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HomeStatCard(
                label: 'Total Main',
                value: '1.2k',
                icon: Icons.sports_esports,
                iconBackground: AppColors.homeTotalTint,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: HomeStatCard(
                label: 'Rating Rata-rata',
                value: '4.8',
                icon: Icons.star,
                highlight: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: HomeStatCard(
                label: 'Host Aktif',
                value: '12',
                icon: Icons.person,
                largeValue: true,
                iconBackground: AppColors.homeHostTint,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: HomeStatCard(
                label: 'Terakhir Update',
                value: _savedAtLabel(),
                icon: Icons.access_time,
                iconBackground: AppColors.homeUpdateTint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space14),
      child: ErrorStateView(message: _error!, onRetry: _sync),
    );
  }

  Widget _buildEmpty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.space14),
      child: EmptyStateView.empty(message: 'Belum ada quiz untukmu.'),
    );
  }
}
