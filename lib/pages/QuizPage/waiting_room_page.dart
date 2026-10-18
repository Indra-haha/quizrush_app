import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../helpers/format.dart';
import '../../helpers/json.dart';
import '../../helpers/room_status_flow.dart';
import '../../models/live_game.dart';
import '../../models/room.dart';
import '../../models/room_message.dart';
import '../../services/active_room_service.dart';
import '../../services/api_client.dart';
import '../../services/quiz_feed.dart';
import '../../services/room_service.dart';
import '../../services/room_socket.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/reaction_overlay.dart';
import '../login_redirect.dart';
import 'live_quiz_page.dart';

/// Ruang tunggu (lobby) quiz setelah PIN terverifikasi.
///
/// Membuka WebSocket `GET /api/rooms?token=<JWT room>` (API.md §9.1) lalu
/// menampilkan status koneksi, pill status room, feed aktivitas (join /
/// leave), kartu PIN + info kuis, grid pemain terhubung, sorakan emote
/// (broadcast tanpa chat teks), dan aksi host (publish / mulai kuis).
class WaitingRoomPage extends StatefulWidget {
  final Room room;
  final String roomToken;
  final String loginToken;

  const WaitingRoomPage({
    super.key,
    required this.room,
    required this.roomToken,
    required this.loginToken,
  });

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

/// Baris feed aktivitas: join / leave peserta, atau baris sistem.
class _FeedEntry {
  final String? name;
  final String text;
  final bool join;
  final DateTime at;

  _FeedEntry.system(this.text) : name = null, join = false, at = DateTime.now();

  _FeedEntry.join(this.name) : text = '', join = true, at = DateTime.now();

  _FeedEntry.leave(this.name) : text = '', join = false, at = DateTime.now();
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  static const _cheers = <String>['🔥', '⚡', '🧠', '🎉'];

  final _feed = <_FeedEntry>[];

  /// Nama pemain yang terlihat di room. Roster awal diambil dari daftar
  /// `names` pada pesan `connected` (API.md §9.1), lalu dirawat lewat event
  /// join / leave / broadcast.
  final _players = <String>{};

  RoomSocket? _socket;
  StreamSubscription<RoomMessage>? _messageSub;
  StreamSubscription<RoomSocketStatus>? _statusSub;
  RoomSocketStatus _status = RoomSocketStatus.connecting;
  int _users = 0;
  String _me = '';
  String _myNama = '';

  /// Label diri sendiri di room: nama tampilan (dipakai sebagai nickname WS)
  /// dengan jatuh ke username bila nama kosong.
  String _myLabel = '';
  String _roomStatus = '';
  String _hostDisplay = '';
  bool _isOwner = false;
  bool _advancing = false;

  /// True sejak soal pertama diterima sampai halaman live ditutup; mencegah
  /// berpindah dua kali ke halaman permainan.
  bool _inGame = false;

  @override
  void initState() {
    super.initState();
    _roomStatus = widget.room.status;
    _connect();
    _checkOwnership();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final user = await SessionService.instance.getUser();
    _me = (user?['username'] as String?)?.trim() ?? '';
    _myNama = (user?['nama'] as String?)?.trim() ?? '';
    _myLabel = _myNama.isNotEmpty ? _myNama : _me;
    if (_myLabel.isNotEmpty) _players.add(_myLabel);
    if (!mounted) return;
    setState(() {});

    // Nickname WS memakai nama tampilan supaya grid pemain menampilkan nama
    // yang bisa dikenali (dan badge host dari `Quizes.host` bisa cocok);
    // identitas game tetap username dari JWT login.
    final socket = RoomSocket(
      roomToken: widget.roomToken,
      loginToken: widget.loginToken,
      name: _myLabel,
    );
    _socket = socket;
    _statusSub = socket.statuses.listen((status) {
      if (!mounted) return;
      setState(() => _status = status);
    });
    _messageSub = socket.messages.listen(_onMessage);
    socket.connect();
  }

  void _reconnect() {
    final socket = _socket;
    if (socket == null || socket.isConnected) return;
    setState(() => _status = RoomSocketStatus.connecting);
    socket.connect();
  }

  /// Pemilik quiz = quiz yang ada di cache "quiz milik saya". Cache kosong
  /// ditarik dulu dari server sebelum menyimpulkan bukan pemilik. Nama host
  /// quiz (`Quizes.host`) ikut disimpan supaya bisa dibedakan dari partisipan
  /// di grid pemain.
  Future<void> _checkOwnership() async {
    final index = await QuizFeed.readCachedMine();
    var mine = index?.quizById(widget.room.quizId);

    if (mine == null) {
      final result = await QuizFeed.syncMine();
      if (!result.needsAuth) {
        mine = result.index?.quizById(widget.room.quizId);
      }
    }

    // Nama pemilik dari cache mana pun (milik sendiri atau feed publik).
    final any = mine ?? await QuizFeed.readCachedQuizById(widget.room.quizId);

    if (!mounted) return;
    setState(() {
      _isOwner = mine != null;
      _hostDisplay = (any?.host ?? '').trim();
    });
  }

  /// Apakah [name] adalah host quiz: pemilik quiz (kita sendiri) atau nama
  /// pemilik quiz dari feed. Peserta lain hanya dikenali lewat nickname WS
  /// (nama tampilan), jadi cocokkan juga nama lengkap diri sendiri terhadap
  /// `host` feed.
  bool _isHost(String name) {
    if (name.isEmpty) return false;
    final isSelf = name == _me || name == _myLabel;
    if (_isOwner && isSelf) return true;
    if (_hostDisplay.isEmpty) return false;
    final lower = _hostDisplay.toLowerCase();
    if (name.toLowerCase() == lower) return true;
    if (isSelf && _myNama.toLowerCase() == lower) return true;
    return false;
  }

  void _onMessage(RoomMessage message) {
    if (!mounted) return;

    // Soal pertama menandai kuis dimulai: pindah ke halaman permainan live
    // (host maupun peserta).
    if (message.type == 'question' && !_inGame) {
      _goLive(message);
      return;
    }

    setState(() {
      if (message.users > 0) _users = message.users;
      switch (message.type) {
        case 'connected':
          // Roster diganti penuh dari daftar server (`names`) plus diri
          // sendiri, supaya klien yang masuk belakangan langsung melihat
          // siapa yang sudah ada — dan reconnect menyegarkan daftar basi.
          _players
            ..clear()
            ..addAll(message.names.where((n) => n.trim().isNotEmpty));
          if (_myLabel.isNotEmpty) _players.add(_myLabel);
          _feed.add(
            _FeedEntry.system('Tersambung ke room. Menunggu peserta lain...'),
          );
        case 'join':
          if (message.from.isNotEmpty) _players.add(message.from);
          _feed.add(_FeedEntry.join(_labelOf(message.from)));
        case 'leave':
          if (message.from.isNotEmpty) _players.remove(message.from);
          _feed.add(_FeedEntry.leave(_labelOf(message.from)));
        case 'broadcast':
        case 'reaction':
          if (message.from.isNotEmpty) _players.add(message.from);
        case 'error':
          break;
        default:
          break;
      }
    });

    switch (message.type) {
      case 'broadcast':
      case 'reaction':
        final reaction = RoomSocket.parseReaction(message.data);
        if (reaction != null) {
          // Sorakan masuk tampil melayang sejenak, tanpa chat teks.
          ReactionOverlay.show(context, reaction);
        } else if (message.data != null) {
          AppSnackBar.show(
            context,
            '${_labelOf(message.from)}: ${message.data}',
            duration: const Duration(milliseconds: 1800),
          );
        }
      case 'error':
        AppSnackBar.error(context, 'Server: ${message.data}');
      default:
        break;
    }
  }

  /// Buka halaman permainan live memakai socket yang sedang aktif.
  void _goLive(RoomMessage message) {
    final socket = _socket;
    if (socket == null) return;

    final question = LiveQuestion.fromJson(jsonMap(message.data));
    _inGame = true;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LiveQuizPage(
              room: widget.room,
              socket: socket,
              loginToken: widget.loginToken,
              myUsername: _me,
              myNama: _myNama,
              initialQuestion: question,
              isHost: _isOwner,
            ),
          ),
        )
        .whenComplete(() {
          if (mounted) setState(() => _inGame = false);
        });
  }

  String _labelOf(String from) {
    if (from.isEmpty) return 'Seseorang';
    if (from == _me || from == _myLabel) return 'Kamu';
    return from;
  }

  void _sendCheer(String emoji, Offset position) {
    HapticFeedback.lightImpact();

    // Optimistic echo: server tidak membalikkan `broadcast` ke pengirim, jadi
    // tampilkan reaksi sendiri secara lokal agar terasa instan (termasuk host).
    ReactionOverlay.show(context, emoji, x: position.dx);

    final socket = _socket;
    if (socket == null || _status != RoomSocketStatus.connected) {
      AppSnackBar.show(context, 'Menunggu koneksi ke room...');
      return;
    }
    socket.sendReaction(emoji);
  }

  Future<void> _copyPin() async {
    final kode = widget.room.kode;
    if (kode.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: kode));
    if (!mounted) return;
    AppSnackBar.success(context, 'PIN ${formatKode(kode)} berhasil disalin!');
  }

  String? get _nextStatus => RoomStatusFlow.next(_roomStatus);

  /// Publish (waiting → open) atau mulai kuis (open → in-Game) oleh host.
  Future<void> _advanceStatus() async {
    final next = _nextStatus;
    if (next == null || _advancing) return;

    final token = await SessionService.instance.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      LoginRedirect.go(context);
      return;
    }

    setState(() => _advancing = true);
    try {
      final updated = await RoomService.instance.updateRoomStatus(
        token: token,
        roomId: widget.room.id,
        status: next,
      );
      if (!mounted) return;
      setState(() {
        _roomStatus = updated.status;
        _advancing = false;
      });

      if (next == 'in-Game') {
        // Jangan pop: server menyiarkan soal pertama lewat WS dan halaman ini
        // (juga milik host) pindah ke [LiveQuizPage] saat pesan itu tiba.
        ActiveRoomService.instance.set(updated);
        AppSnackBar.success(context, 'Kuis dimulai. Sukses untuk semua!');
      } else {
        AppSnackBar.success(context, 'Room berhasil dipublish.');
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await SessionService.instance.clear();
        ActiveRoomService.instance.clear();
        if (!mounted) return;
        LoginRedirect.go(context);
        return;
      }
      if (!mounted) return;
      setState(() => _advancing = false);
      AppSnackBar.error(
        context,
        e.message.isNotEmpty ? e.message : 'Gagal mengubah status room.',
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _advancing = false);
      AppSnackBar.error(context, 'Tidak bisa terhubung ke server. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Semua teks di halaman ini dibesarkan sedikit agar lebih mudah dibaca.
    final textScaler = MediaQuery.textScalerOf(
      context,
    ).clamp(minScaleFactor: 1.15);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: _buildHeader(context),
        body: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.space8,
              AppSpacing.space6,
              AppSpacing.space8,
              AppSpacing.space12,
            ),
            children: [
              _statusPill(),
              const SizedBox(height: AppSpacing.space6),
              _activityCard(),
              const SizedBox(height: AppSpacing.space6),
              _pinCard(),
              const SizedBox(height: AppSpacing.space8),
              _playersSection(),
              const SizedBox(height: AppSpacing.space6),
              _cheerCard(),
              if (_isOwner && _nextStatus != null) ...[
                const SizedBox(height: AppSpacing.space6),
                _startBox(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    const headerHeight = kToolbarHeight + AppSpacing.space4;
    return PreferredSize(
      preferredSize: Size.fromHeight(headerHeight + topPadding),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            bottom: BorderSide(
              color: AppColors.primaryBorder.withValues(alpha: 0.4),
              width: AppBorderWidth.hairline,
            ),
          ),
          boxShadow: AppShadows.hairline,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: headerHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
              ),
              child: Row(
                children: [
                  _headerBoxButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Kembali',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  Expanded(
                    child: Text(
                      widget.room.displayTitle.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.heading3,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  _headerBoxButton(
                    icon: Icons.refresh,
                    tooltip: 'Sambungkan ulang',
                    enabled: _status != RoomSocketStatus.connected,
                    onPressed: _reconnect,
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  _headerAvatar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerBoxButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: AppIconSize.body),
        color: enabled ? AppColors.primary : AppColors.textMuted,
        style: IconButton.styleFrom(
          minimumSize: const Size(AppIconSize.xxl + 8, AppIconSize.xxl + 8),
          backgroundColor: AppColors.primarySoft,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
      ),
    );
  }

  Widget _headerAvatar() {
    final initial = _me.trim().isEmpty ? '?' : _me.trim()[0].toUpperCase();
    return Container(
      width: AppIconSize.xxl + 4,
      height: AppIconSize.xxl + 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: AppShadows.card,
      ),
      child: Text(
        initial,
        style: AppTextStyles.labelStrongSmallOnPrimary.copyWith(
          fontSize: AppFontSize.small,
        ),
      ),
    );
  }

  String get _roomStatusLabel => switch (_roomStatus) {
    'waiting' || 'open' => 'MENUNGGU HOST MEMULAI',
    'in-Game' => 'KUIS BERLANGSUNG',
    'ended' => 'ROOM SELESAI',
    _ => _roomStatus.toUpperCase(),
  };

  Widget _statusPill() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space3,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: AppRadius.pill,
            boxShadow: AppShadows.hairlineTight,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: AppSpacing.space5,
                height: AppSpacing.space5,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                _roomStatusLabel,
                style: AppTextStyles.bodyCaption.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: 0.55,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityCard() {
    final entries = _feed.reversed.take(5).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.4),
        ),
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in entries) ...[
            _feedRow(entry),
            const SizedBox(height: AppSpacing.space3),
          ],
          _connectionFooter(),
        ],
      ),
    );
  }

  Widget _feedRow(_FeedEntry entry) {
    if (entry.name == null) {
      return Text(
        entry.text,
        style: AppTextStyles.bodyCaption.copyWith(
          color: AppColors.textSecondary,
        ),
      );
    }

    final name = entry.name!;
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Row(
      children: [
        Container(
          width: AppIconSize.xxl,
          height: AppIconSize.xxl,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: AppTextStyles.labelStrongSmallOnPrimary.copyWith(
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: name,
                      style: AppTextStyles.bodyMeta.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    TextSpan(
                      text: entry.join ? ' bergabung!' : ' keluar.',
                      style: AppTextStyles.bodyMeta.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                relativeTime(entry.at.toIso8601String()),
                style: AppTextStyles.bodyCaption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: AppFontWeight.regular,
                ),
              ),
            ],
          ),
        ),
        if (entry.join)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space2,
              vertical: AppSpacing.space1,
            ),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              'BARU',
              style: AppTextStyles.bodyCaption.copyWith(
                color: AppColors.primaryDark,
                fontWeight: AppFontWeight.bold,
                letterSpacing: 0.28,
              ),
            ),
          ),
      ],
    );
  }

  Widget _connectionFooter() {
    final canRetry = _status == RoomSocketStatus.disconnected;

    return GestureDetector(
      onTap: canRetry ? _reconnect : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space2,
          vertical: AppSpacing.space1,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.space4,
              height: AppSpacing.space4,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              _statusLabel,
              style: AppTextStyles.bodyCaption.copyWith(
                color: AppColors.textSecondary,
                fontWeight: AppFontWeight.medium,
                letterSpacing: 0.33,
              ),
            ),
            const Spacer(),
            Text(
              '•',
              style: AppTextStyles.bodyCaption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.space3),
            Text(
              canRetry ? 'Ketuk untuk sambung ulang' : 'Auto-sync ON',
              style: AppTextStyles.bodyCaption.copyWith(
                color: canRetry ? AppColors.error : AppColors.primary,
                fontWeight: AppFontWeight.semibold,
                letterSpacing: 0.33,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinCard() {
    final quiz = widget.room.quiz;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.4),
        ),
        borderRadius: AppRadius.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'KODE AKSES RUANGAN (PIN)',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyCaption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: AppFontWeight.semibold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatKode(widget.room.kode),
                textAlign: TextAlign.center,
                style: AppTextStyles.code.copyWith(
                  color: AppColors.primary,
                  fontSize: AppFontSize.heading,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Tooltip(
                message: 'Salin PIN',
                child: IconButton(
                  onPressed: _copyPin,
                  icon: const Icon(Icons.copy_rounded),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primarySoft,
                    shape: const CircleBorder(),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          Container(
            padding: const EdgeInsets.all(AppSpacing.space4),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(
                color: AppColors.primaryBorder.withValues(alpha: 0.2),
              ),
              borderRadius: AppRadius.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppIconSize.xxl + 8,
                  height: AppIconSize.xxl + 8,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: AppRadius.sm,
                    boxShadow: AppShadows.hairlineTight,
                  ),
                  child: const Icon(
                    Icons.quiz_outlined,
                    color: AppColors.textOnPrimary,
                    size: AppIconSize.lg,
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.displayTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading3,
                      ),
                      if (quiz != null && quiz.description.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          quiz.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: AppFontWeight.regular,
                          ),
                        ),
                      ],
                      if (quiz != null) ...[
                        const SizedBox(height: AppSpacing.space3),
                        Wrap(
                          spacing: AppSpacing.space4,
                          runSpacing: AppSpacing.space2,
                          children: [
                            _infoChip('${quiz.totalQuestions} Soal'),
                            _infoChip('PIN ${formatKode(widget.room.kode)}'),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.2),
        ),
        borderRadius: AppRadius.sm,
      ),
      child: Text(
        label,
        style: AppTextStyles.bodyCaption.copyWith(
          fontWeight: AppFontWeight.medium,
          letterSpacing: 0.33,
        ),
      ),
    );
  }

  Widget _playersSection() {
    final players = _players.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Pemain Terhubung', style: AppTextStyles.heading3),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space5,
                vertical: AppSpacing.space1,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.pill,
                boxShadow: AppShadows.hairlineTight,
              ),
              child: Text(
                '$_users',
                style: AppTextStyles.bodyCaption.copyWith(
                  color: AppColors.textOnPrimary,
                  fontWeight: AppFontWeight.bold,
                  letterSpacing: 0.33,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        if (players.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary,
              border: Border.all(
                color: AppColors.primaryBorder.withValues(alpha: 0.4),
              ),
              borderRadius: AppRadius.md,
            ),
            child: Text(
              'Belum ada pemain lain yang terhubung.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyCaption,
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSpacing.space8) / 3;
              return Wrap(
                spacing: AppSpacing.space4,
                runSpacing: AppSpacing.space4,
                children: [
                  for (final name in players)
                    _playerCard(name, cardWidth, isHost: _isHost(name)),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _playerCard(String name, double width, {required bool isHost}) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space2,
        vertical: AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: isHost
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primaryBorder.withValues(alpha: 0.4),
          width: isHost ? AppBorderWidth.thin : AppBorderWidth.hairline,
        ),
        borderRadius: AppRadius.md,
        boxShadow: isHost ? AppShadows.subtle : AppShadows.hairlineTight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: AppIconSize.hero,
                height: AppIconSize.hero,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isHost ? AppColors.primary : AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  initial,
                  style: AppTextStyles.heading3.copyWith(
                    color: isHost ? AppColors.textOnPrimary : AppColors.primary,
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: AppIconSize.md,
                  height: AppIconSize.md,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.textOnPrimary,
                      width: AppBorderWidth.regular,
                    ),
                  ),
                ),
              ),
              if (isHost)
                Positioned(
                  top: -6,
                  right: -4,
                  child: Container(
                    width: AppIconSize.md,
                    height: AppIconSize.md,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.textOnPrimary,
                        width: AppBorderWidth.regular,
                      ),
                      boxShadow: AppShadows.hairlineTight,
                    ),
                    child: const Text(
                      '👑',
                      style: TextStyle(fontSize: AppFontSize.micro),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            trimmed,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: AppTextStyles.bodyMeta,
          ),
          Text(
            isHost ? 'Host' : 'Partisipan',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyCaption.copyWith(
              fontSize: AppFontSize.caption,
              color: isHost ? AppColors.primary : AppColors.textMuted,
              fontWeight: isHost ? AppFontWeight.bold : AppFontWeight.medium,
              letterSpacing: isHost ? 0.5 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cheerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primaryBorder.withValues(alpha: 0.4),
        ),
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'SORAKAN LIVE:',
                  style: AppTextStyles.bodyCaption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: AppFontWeight.bold,
                    letterSpacing: 0.55,
                  ),
                ),
              ),
              Text(
                'Ketuk untuk kirim ke room',
                style: AppTextStyles.bodyCaption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: AppFontWeight.medium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [for (final emoji in _cheers) _cheerButton(emoji)],
          ),
        ],
      ),
    );
  }

  Widget _cheerButton(String emoji) {
    final connected = _status == RoomSocketStatus.connected;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
        child: InkWell(
          onTapUp: (details) => _sendCheer(emoji, details.globalPosition),
          borderRadius: AppRadius.sm,
          child: Container(
            height: AppSpacing.space13 + AppSpacing.space8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: connected
                  ? AppColors.primarySoft
                  : AppColors.primarySoft.withValues(alpha: 0.5),
              borderRadius: AppRadius.sm,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 28)),
          ),
        ),
      ),
    );
  }

  Widget _startBox() {
    final starting = _roomStatus == 'open';
    final label = starting
        ? 'Mulai Kuis Sekarang ($_users Siap)'
        : RoomStatusFlow.publishMeta(_nextStatus).$1;
    final subtitle = starting
        ? 'Kuis akan otomatis dimulai pada layar semua peserta seketika.'
        : 'Room akan tampil di daftar room dan peserta bisa masuk.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPrimaryButton(
            label: label,
            icon: starting ? Icons.play_circle_outline : null,
            loading: _advancing,
            loadingLabel: 'Memproses...',
            radius: 12,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space6),
            onPressed: _advanceStatus,
          ),
          const SizedBox(height: AppSpacing.space3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: AppFontWeight.regular,
            ),
          ),
        ],
      ),
    );
  }

  Color get _statusColor => switch (_status) {
    RoomSocketStatus.connecting ||
    RoomSocketStatus.reconnecting => AppColors.warning,
    RoomSocketStatus.connected => AppColors.success,
    RoomSocketStatus.disconnected => AppColors.error,
  };

  String get _statusLabel => switch (_status) {
    RoomSocketStatus.connecting => 'Menyambung...',
    RoomSocketStatus.reconnecting => 'Menyambung ulang...',
    RoomSocketStatus.connected => 'Server Aktif',
    RoomSocketStatus.disconnected => 'Koneksi terputus',
  };
}
