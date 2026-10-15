import 'package:flutter/material.dart';

import '../../helpers/room_status_flow.dart';
import '../../models/quiz.dart';
import '../../services/active_room_service.dart';
import '../../services/api_client.dart';
import '../../services/quiz_feed.dart';
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
import '../login_redirect.dart';

final _optionColors = [
  optionThemes[1].dot,
  optionThemes[2].dot,
  optionThemes[3].dot,
  optionThemes[0].dot,
];

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

  String? get _nextStatus => RoomStatusFlow.next(_room.status);

  (String, IconData) get _publishMeta =>
      RoomStatusFlow.publishMeta(_nextStatus);

  /// Detail room dibaca dari cache; server hanya dihubungi lewat tombol
  /// refresh atau setelah status room diubah.
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

    final result = await QuizFeed.syncMine();
    if (!mounted) return;

    if (result.needsAuth) {
      LoginRedirect.go(context);
      return;
    }

    setState(() {
      final quiz = result.index?.quizById(widget.quizId);
      if (quiz != null) _apply(quiz);
      _error = result.error;
      _loading = false;
    });
  }

  RoomSummary? _findRoom(Quizes quiz, RoomSummary room) {
    for (final r in quiz.rooms) {
      if (r.id == room.id) return r;
    }
    return null;
  }

  Future<void> _publish() async {
    final next = _nextStatus;
    if (next == null) return;

    final token = await SessionService.instance.getToken();
    if (!mounted) return;
    if (token == null) {
      LoginRedirect.go(context);
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
        ActiveRoomService.instance.clear();
        if (!mounted) return;
        LoginRedirect.go(context);
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

  @override
  Widget build(BuildContext context) {
    final title = _quiz?.title;
    return Scaffold(
      backgroundColor: AppColors.surface,
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space8,
        AppSpacing.space9,
        AppSpacing.space12,
      ),
      children: [
        _heroCard(quiz),
        const SizedBox(height: AppSpacing.space10),
        const SectionHeader(title: 'Jumlah Pertanyaan'),
        const SizedBox(height: AppSpacing.space8),
        for (final (i, q) in preview.indexed) ...[
          _questionCard(q, i),
          if (i < preview.length - 1) const SizedBox(height: AppSpacing.space8),
        ],
        if (remaining > 0) ...[
          const SizedBox(height: AppSpacing.space8),
          _loadMoreButton(total, remaining),
        ],
        const SizedBox(height: AppSpacing.space10),
        _publishButton(),
      ],
    );
  }

  Widget _heroCard(Quizes quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.layeredCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.space4,
            runSpacing: AppSpacing.space4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (_room.kode.isNotEmpty)
                _pill(
                  color: AppColors.primary,
                  textColor: AppColors.textOnPrimary,
                  text: _room.kode,
                ),
              _statusPill(),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(_room.kode, style: AppTextStyles.heading1),
          if (quiz.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Text(
              quiz.description,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.space9),
          AppStatTile.detailed(
            icon: Icons.list_alt,
            iconBg: AppColors.primarySoft,
            value: '${quiz.questions.length}',
            label: 'Total Pertanyaan',
          ),
          const SizedBox(height: AppSpacing.space4),
          AppStatTile.detailed(
            icon: Icons.timer_outlined,
            iconBg: AppColors.surface,
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
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.layeredCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _pill(
                color: AppColors.primary,
                textColor: AppColors.textOnPrimary,
                text: 'Soal ${index + 1}',
              ),
              const SizedBox(width: AppSpacing.space4),
              _pill(
                color: AppColors.surfaceSoft,
                textColor: AppColors.textSecondary,
                text: formatQDuration(q.duration),
              ),
              const Spacer(),
              Text(
                '${q.skor} Pts',
                style: AppTextStyles.statLabelOnPrimary.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            q.question,
            style: AppTextStyles.buttonLarge.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          for (final (i, option) in q.options.indexed) ...[
            _optionTile(option, i),
            if (i < q.options.length - 1)
              const SizedBox(height: AppSpacing.space4),
          ],
        ],
      ),
    );
  }

  Widget _optionTile(String option, int index) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.hairlineTight,
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
              borderRadius: AppRadius.md,
            ),
            child: Text(
              String.fromCharCode(65 + index),
              style: AppTextStyles.labelStrongSmall.copyWith(
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.space1),
              child: Text(option, style: AppTextStyles.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loadMoreButton(int total, int remaining) {
    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: AppRadius.md,
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: () => setState(() => _visibleCount = total),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space10,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            boxShadow: AppShadows.hairlineTight,
          ),
          child: Text(
            'Muat $remaining Soal Lainnya (Total $total Soal)',
            textAlign: TextAlign.center,
            style: AppTextStyles.labelStrong.copyWith(color: AppColors.primary),
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
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.space7),
        onPressed: disabled ? null : _publish,
      ),
    );
  }
}
