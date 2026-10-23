import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../helpers/format.dart';
import '../../helpers/json.dart';
import '../../helpers/room_roster.dart';
import '../../helpers/room_status_flow.dart';
import '../../models/live_game.dart';
import '../../models/quiz.dart';
import '../../models/room.dart';
import '../../models/room_message.dart';
import '../../services/active_room_service.dart';
import '../../services/api_client.dart';
import '../../services/profile_settings_service.dart';
import '../../services/quiz_feed.dart';
import '../../services/room_service.dart';
import '../../services/room_socket.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/quiz_waiting.dart';
import '../../widgets/reaction_overlay.dart';
import '../login_redirect.dart';
import 'live_quiz_page.dart';

/// Ruang tunggu (lobby) quiz setelah PIN terverifikasi.
///
/// Membuka WebSocket `GET /api/rooms?token=<JWT room>` (API.md §9.1) lalu
/// menampilkan hero berisi judul kuis, ringkasan jumlah soal & total poin,
/// dan GAME PIN; kartu ringkasan room (jumlah peserta, status room, kondisi
/// koneksi); grid pemain terhubung; sorakan emote (broadcast tanpa chat
/// teks); serta aksi host (publish / mulai kuis).
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

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  static const _cheers = <String>['🔥', '⚡', '🧠', '🎉'];

  /// Minimal jumlah kartu di grid peserta (slot kosong ikut dihitung).
  static const _minParticipantSlots = 4;
  static const _shakeThreshold = 12.0;
  static const _shakeCooldown = Duration(milliseconds: 1500);

  StreamSubscription<UserAccelerometerEvent>? _accelerometerSub;
  DateTime _lastShakeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _accelerometerEnabled = false;

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

  /// True kalau kepemilikan belum bisa dipastikan karena sinkronisasi cache
  /// gagal (bukan karena kuis memang bukan milik pengguna).
  bool _ownershipUnknown = false;

  /// Kuis room ini (dari cache feed), dipakai untuk menampilkan jumlah soal
  /// dan total poin pada kartu hero.
  Quizes? _quiz;

  /// True sejak soal pertama diterima sampai halaman live ditutup; mencegah
  /// berpindah dua kali ke halaman permainan.
  bool _inGame = false;

  @override
  void initState() {
    super.initState();
    // Status room dari server; `waiting` adalah default server (API.md §5.1)
    // supaya status kosong tidak membuat alur publish kehilangan tombol.
    _roomStatus = widget.room.status.isEmpty ? 'waiting' : widget.room.status;
    _loadSensorSettings();
    _connect();
  }

  Future<void> _loadSensorSettings() async {
    final enabled = await ProfileSettingsService.instance.accelerometerEnabled();
    if (!mounted || !enabled) return;
    _accelerometerEnabled = true;
    _startShakeDetection();
  }

  void _startShakeDetection() {
    _accelerometerSub?.cancel();
    _accelerometerSub = userAccelerometerEventStream().listen((event) {
      if (!_accelerometerEnabled || !mounted) return;
      final magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      if (magnitude < _shakeThreshold) return;
      final now = DateTime.now();
      if (now.difference(_lastShakeAt) < _shakeCooldown) return;
      _lastShakeAt = now;
      _sendAutoCheer();
    });
  }

  void _sendAutoCheer() {
    if (_status != RoomSocketStatus.connected) return;
    final emoji = _cheers[Random().nextInt(_cheers.length)];
    HapticFeedback.mediumImpact();
    final size = MediaQuery.of(context).size;
    ReactionOverlay.show(context, emoji, x: size.width / 2);
    final socket = _socket;
    if (socket == null) return;
    socket.sendReaction(emoji);
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
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
      // Kalau sync "my quizzes" tadi gagal (jaringan putus sesaat), coba lagi
      // saat socket terhubung supaya tombol host tetap muncul.
      if (status == RoomSocketStatus.connected && _ownershipUnknown) {
        _ownershipUnknown = false;
        _checkOwnership();
      }
    });
    _messageSub = socket.messages.listen(_onMessage);
    socket.connect();

    // Cek kepemilikan butuh identitas sesi (nama/username), jadi baru jalan
    // setelah [_connect] selesai memuat sesi.
    _checkOwnership();
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
      // Kuis memang bukan milik kita (cache sinkron tapi tidak ada) berbeda
      // dengan "belum bisa dipastikan" karena jaringan gagal.
      if (mine == null && result.error != null) _ownershipUnknown = true;
    }

    // Nama pemilik dari cache mana pun (milik sendiri atau feed publik).
    final any = mine ?? await QuizFeed.readCachedQuizById(widget.room.quizId);

    if (!mounted) return;
    setState(() {
      _isOwner = mine != null || _hostIsSelf(any?.host ?? '');
      _hostDisplay = (any?.host ?? '').trim();
      _quiz = any;
      if (_isOwner) _ownershipUnknown = false;
    });
  }

  /// Cadangan deteksi host: nama host kuis dari feed dibandingkan dengan nama
  /// tampilan/username sesi ini. Dipakai kalau kuis tidak ada di cache
  /// "my quizzes" (mis. host masuk lewat PIN atau cache belum ter-sync).
  bool _hostIsSelf(String host) {
    final trimmed = host.trim();
    if (trimmed.isEmpty) return false;
    final lower = trimmed.toLowerCase();
    if (_myNama.toLowerCase() == lower) return true;
    return _me.toLowerCase() == lower;
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
          //
          // `names` hanya berisi klien yang SUDAH terhubung sebelumnya
          // (API.md §9.1), jadi klien ini wajib menambah dirinya sendiri.
          _players
            ..clear()
            ..addAll(RoomRoster.merge(message.names, _myLabel));
        case 'join':
          if (message.from.isNotEmpty) _players.add(message.from);
        case 'leave':
          if (message.from.isNotEmpty) _players.remove(message.from);
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
              AppSpacing.none,
              AppSpacing.space6,
              AppSpacing.none,
              AppSpacing.space12,
            ),
            children: [
              _heroCard(),
              const SizedBox(height: AppSpacing.space8),
              _statsCard(),
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

  /// Kartu hero ruang tunggu: judul kuis, ringkasan jumlah soal & total poin,
  /// serta GAME PIN (ketuk untuk menyalin kode).
  Widget _heroCard() {
    final questionCount =
        _quiz?.questionCount ?? widget.room.quiz?.totalQuestions ?? 0;
    final totalPoints = _quiz?.score ?? 0;
    // Judul kuis (dari cache feed) lebih spesifik daripada judul room.
    final quizTitle = _quiz?.title.trim() ?? '';
    final title = quizTitle.isNotEmpty ? quizTitle : widget.room.displayTitle;

    return QuizWaitingHero(
      title: title,
      pin: widget.room.kode,
      onCopyPin: _copyPin,
      stats: [
        if (questionCount > 0)
          QuizWaitingHeroStat(
            value: '$questionCount',
            icon: Icons.list_alt,
            background: AppColors.heroLime,
            foreground: AppColors.primary,
          ),
        if (totalPoints > 0)
          QuizWaitingHeroStat(
            value: formatPoints(totalPoints),
            icon: Icons.star_rounded,
            background: AppColors.heroPeach,
            foreground: AppColors.primary,
          ),
      ],
    );
  }

  /// Ringkasan room: jumlah peserta, status room, dan kondisi koneksi.
  Widget _statsCard() {
    return QuizWaitingStats(
      participantCount: _participantCount,
      statusLabel: RoomStatusFlow.label(_roomStatus),
      connected: _status == RoomSocketStatus.connected,
      onReconnect: _reconnect,
    );
  }

  /// Jumlah peserta yang tampil: roster lokal bisa lebih lengkap daripada
  /// angka server (mis. saat klien masuk belakangan), jadi ambil yang besar.
  int get _participantCount =>
      _users > _players.length ? _users : _players.length;

  /// Grid peserta yang terhubung, diisi slot kosong sampai minimal
  /// [_minParticipantSlots] kartu supaya layout tetap rapi saat room baru.
  Widget _playersSection() {
    final players = _players.toList();

    if (players.isEmpty) {
      return Container(
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
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - AppSpacing.space4) / 2;
        final slots = players.length < _minParticipantSlots
            ? _minParticipantSlots - players.length
            : 0;

        return Wrap(
          spacing: AppSpacing.space4,
          runSpacing: AppSpacing.space4,
          children: [
            for (final name in players)
              SizedBox(
                width: cardWidth,
                child: QuizWaitingParticipant(
                  name: name,
                  isHost: _isHost(name),
                ),
              ),
            for (var i = 0; i < slots; i++)
              SizedBox(width: cardWidth, child: const QuizWaitingSlot()),
          ],
        );
      },
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
        ? 'Mulai Kuis Sekarang ($_participantCount Siap)'
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
}
