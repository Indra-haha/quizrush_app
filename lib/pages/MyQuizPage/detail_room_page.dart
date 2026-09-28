import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/quiz.dart';
import '../../services/api_client.dart';
import '../../services/quiz_cache_service.dart';
import '../../services/quiz_service.dart';
import '../../services/room_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_option_theme.dart';
import '../../utils/format.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_pill.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/app_stat_tile.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/section_header.dart';
import '../login_page.dart';

const _statusFlow = ['waiting', 'open', 'in-Game', 'ended'];
final _optionColors = [
  optionThemes[1].dot,
  optionThemes[2].dot,
  optionThemes[3].dot,
  optionThemes[0].dot,
];

typedef PublishResult = ({String previous, String next});

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

  /// Room list untuk satu kuis dibaca dari cache; tombol refresh yang mengisi
  /// ulang cache dari server.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await QuizCacheService.instance.getQuizById(widget.quizId);
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

    final token = await SessionService.instance.getToken();
    if (token == null) {
      _goToLogin();
      return;
    }

    try {
      final data = await QuizService.instance.getMyQuizzes(token);
      await QuizCacheService.instance.saveMyQuizzes(data);
      if (!mounted) return;
      setState(() {
        _quiz = _findQuiz(data, widget.quizId);
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
      debugPrint('Rooms sync error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server. ($e)';
        _loading = false;
      });
    }
  }

  Quizes? _findQuiz(MyQuizzes data, String id) {
    for (final quiz in data.all) {
      if (quiz.id == id) return quiz;
    }
    return null;
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
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
      padding: const EdgeInsets.all(16.0),
      itemCount: rooms.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final data = rooms[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () async {
              final navigator = Navigator.of(context);
              final result = await navigator.push<PublishResult>(
                MaterialPageRoute<PublishResult>(
                  builder: (_) =>
                      RoomDetailPage(quizId: widget.quizId, room: data),
                ),
              );
              if (!mounted) return;
              if (result != null) {
                navigator.pop(result);
              } else {
                _load();
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          data.kode,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (data.status.isNotEmpty)
                        Chip(
                          label: Text(data.status),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  if (quiz.title.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(quiz.title, style: const TextStyle(fontSize: 14)),
                  ],
                  if (data.createdAt.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      data.createdAt,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class RoomDetailPage extends StatefulWidget {
  final String quizId;
  final RoomSummary room;

  const RoomDetailPage({super.key, required this.quizId, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  late RoomSummary _room = widget.room;
  Quizes? _quiz;
  bool _loading = true;
  bool _publishing = false;
  String? _error;
  int _visibleCount = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String? get _nextStatus {
    final idx = _statusFlow.indexOf(_room.status);
    if (idx < 0 || idx >= _statusFlow.length - 1) return null;
    return _statusFlow[idx + 1];
  }

  (String, IconData) get _publishMeta {
    switch (_nextStatus) {
      case 'open':
        return ('Publish', Icons.rocket_launch_outlined);
      case 'in-Game':
        return ('Mulai Game', Icons.play_circle_outline);
      case 'ended':
        return ('Akhiri', Icons.flag_outlined);
      default:
        return ('Selesai', Icons.check_circle_outline);
    }
  }

  /// Detail room dibaca dari cache; server hanya dihubungi lewat tombol
  /// refresh atau setelah status room diubah.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final cached = await QuizCacheService.instance.getQuizById(widget.quizId);
    if (!mounted) return;
    if (cached == null) {
      await _sync();
      return;
    }
    setState(() {
      _apply(cached);
      _loading = false;
    });
  }

  void _apply(Quizes quiz) {
    _quiz = quiz;
    final room = _findRoom(quiz, widget.room);
    if (room != null) _room = room;
  }

  Future<void> _sync() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await SessionService.instance.getToken();
    if (token == null) {
      _goToLogin();
      return;
    }

    try {
      final data = await QuizService.instance.getMyQuizzes(token);
      await QuizCacheService.instance.saveMyQuizzes(data);
      if (!mounted) return;
      setState(() {
        final quiz = _findQuiz(data, widget.quizId);
        if (quiz != null) _apply(quiz);
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
      debugPrint('Room detail sync error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server. ($e)';
        _loading = false;
      });
    }
  }

  RoomSummary? _findRoom(Quizes quiz, RoomSummary room) {
    for (final r in quiz.rooms) {
      if (r.id == room.id) return r;
    }
    return null;
  }

  Quizes? _findQuiz(MyQuizzes data, String id) {
    for (final quiz in data.all) {
      if (quiz.id == id) return quiz;
    }
    return null;
  }

  Future<void> _publish() async {
    final next = _nextStatus;
    if (next == null) return;

    final token = await SessionService.instance.getToken();
    if (token == null) {
      _goToLogin();
      return;
    }

    setState(() => _publishing = true);
    try {
      await RoomService.instance.updateRoomStatus(
        token: token,
        roomId: _room.id,
        status: next,
      );
      if (!mounted) return;
      Navigator.of(context).pop((previous: _room.status, next: next));
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await SessionService.instance.clear();
        _goToLogin();
        return;
      }
      if (!mounted) return;
      setState(() => _publishing = false);
      AppSnackBar.error(context, e.message);
    } catch (e) {
      debugPrint('Publish error: $e');
      if (!mounted) return;
      setState(() => _publishing = false);
      AppSnackBar.error(context, 'Gagal mengubah status room.');
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _quiz?.title;
    return Scaffold(
      backgroundColor: AppColors.cardBg,
      appBar: AppHeaderBarWithActions(
        title: title == null || title.isEmpty ? 'Detail Room' : title,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
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

    final total = quiz.questions.length;
    final preview = quiz.questions.take(_visibleCount).toList();
    final remaining = total - preview.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _heroCard(quiz),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Jumlah Pertanyaan'),
        const SizedBox(height: 16),
        for (final (i, q) in preview.indexed) ...[
          _questionCard(q, i),
          if (i < preview.length - 1) const SizedBox(height: 16),
        ],
        if (remaining > 0) ...[
          const SizedBox(height: 16),
          _loadMoreButton(total, remaining),
        ],
        const SizedBox(height: 24),
        _publishButton(),
      ],
    );
  }

  Widget _heroCard(Quizes quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.heroBg,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_room.kode.isNotEmpty)
                _pill(
                  color: AppColors.badgePurple,
                  textColor: Colors.white,
                  text: _room.kode,
                ),
              _statusPill(),
            ],
          ),
          const SizedBox(height: 16),
          Text(_room.kode, style: AppTextStyles.heading1),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              quiz.description,
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.muted,
                fontSize: 16,
                fontWeight: FontWeight.w400,
                height: 1.50,
              ),
            ),
          ],
          const SizedBox(height: 20),
          AppStatTile.detailed(
            icon: Icons.list_alt,
            iconBg: AppColors.softLavender,
            value: '${quiz.questions.length}',
            label: 'Total Pertanyaan',
          ),
          const SizedBox(height: 8),
          AppStatTile.detailed(
            icon: Icons.timer_outlined,
            iconBg: AppColors.warmSurface,
            value: formatDuration(totalDuration(quiz)),
            label: 'Durasi Kuis',
          ),
        ],
      ),
    );
  }

  Widget _pill({
    required Color color,
    required Color textColor,
    required String text,
  }) {
    return AppPill(
      text: text,
      background: color,
      foreground: textColor,
      elevated: true,
    );
  }

  Widget _statusPill() {
    return AppPill.roomStatus(_room.status);
  }

  Widget _questionCard(QuizQuestion q, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 4,
            offset: Offset(0, 2),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: AppColors.shadowCard,
            blurRadius: 6,
            offset: Offset(0, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pill(
                color: AppColors.highlight,
                textColor: Colors.white,
                text: 'Soal ${index + 1}',
              ),
              const SizedBox(width: 8),
              _pill(
                color: AppColors.heroBg,
                textColor: AppColors.muted,
                text: formatQDuration(q.duration),
              ),
              const Spacer(),
              Text(
                '${q.skor} Pts',
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.ptsInk,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.33,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            q.question,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.56,
            ),
          ),
          const SizedBox(height: 12),
          for (final (i, option) in q.options.indexed) ...[
            _optionTile(option, i),
            if (i < q.options.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(String option, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.optionBg,
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowSoft,
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _optionColors[index % _optionColors.length],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              String.fromCharCode(65 + index),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 1.33,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                option,
                style: GoogleFonts.plusJakartaSans(
                  color: AppColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMoreButton(int total, int remaining) {
    return Material(
      color: AppColors.heroBg,
      borderRadius: BorderRadius.circular(32),
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: () => setState(() => _visibleCount = total),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowSoft,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            'Muat $remaining Soal Lainnya (Total $total Soal)',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: AppColors.primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.43,
            ),
          ),
        ),
      ),
    );
  }

  Widget _publishButton() {
    final meta = _publishMeta;
    final disabled = _nextStatus == null;
    return SizedBox(
      width: double.infinity,
      child: AppPrimaryButton(
        label: meta.$1,
        icon: meta.$2,
        loading: _publishing,
        radius: 14,
        padding: const EdgeInsets.symmetric(vertical: 14),
        onPressed: disabled ? null : _publish,
      ),
    );
  }
}
