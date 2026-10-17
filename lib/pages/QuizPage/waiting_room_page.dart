import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/room.dart';
import '../../models/room_message.dart';
import '../../services/room_socket.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../helpers/format.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_hero_card.dart';
import '../../widgets/room_chat_bubble.dart';
import '../../widgets/room_composer.dart';
import '../../widgets/room_connection_bar.dart';
import '../../widgets/status_badge.dart';

/// Ruang tunggu (lobby) quiz setelah PIN terverifikasi.
///
/// Membuka WebSocket `GET /api/rooms?token=<JWT room>` (API.md §9.1) lalu
/// menampilkan status koneksi, jumlah pemain di room (`users`), dan chat
/// antar pemain (pesan `broadcast`).
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

class _ChatEntry {
  final String? from;
  final String text;
  final bool mine;

  /// Baris sistem (konek / join / leave), bukan bubble chat.
  const _ChatEntry.system(this.text) : from = null, mine = false;

  const _ChatEntry.chat({
    required this.from,
    required this.text,
    required this.mine,
  });
}

class _WaitingRoomPageState extends State<WaitingRoomPage> {
  final _entries = <_ChatEntry>[];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  RoomSocket? _socket;
  StreamSubscription<RoomMessage>? _messageSub;
  StreamSubscription<RoomSocketStatus>? _statusSub;
  RoomSocketStatus _status = RoomSocketStatus.connecting;
  int _users = 0;
  String _me = '';

  @override
  void initState() {
    super.initState();
    _connect();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _statusSub?.cancel();
    _socket?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final user = await SessionService.instance.getUser();
    _me = (user?['username'] as String?)?.trim() ?? '';
    if (!mounted) return;

    final socket = RoomSocket(
      roomToken: widget.roomToken,
      loginToken: widget.loginToken,
      name: _me,
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

  void _onMessage(RoomMessage message) {
    if (!mounted) return;
    setState(() {
      if (message.users > 0) _users = message.users;
      switch (message.type) {
        case 'connected':
          _entries.add(
            const _ChatEntry.system('Tersambung ke room. Menunggu peserta lain...'),
          );
        case 'join':
          _entries.add(_ChatEntry.system('${_labelOf(message.from)} bergabung.'));
        case 'leave':
          _entries.add(_ChatEntry.system('${_labelOf(message.from)} keluar.'));
        case 'broadcast':
          _entries.add(
            _ChatEntry.chat(
              from: message.from,
              text: '${message.data}',
              mine: message.from == _me,
            ),
          );
        case 'error':
          _entries.add(_ChatEntry.system('Server: ${message.data}'));
        default:
          break;
      }
    });
    _scrollToBottom();
  }

  String _labelOf(String from) {
    if (from.isEmpty) return 'Seseorang';
    if (from == _me) return 'Kamu';
    return from;
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    final socket = _socket;
    if (socket == null || _status != RoomSocketStatus.connected) return;

    socket.sendBroadcast(text);
    _textController.clear();
    FocusScope.of(context).unfocus();
    setState(() {
      _entries.add(
        _ChatEntry.chat(from: _me.isEmpty ? 'Kamu' : _me, text: text, mine: true),
      );
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBarWithActions(
        title: 'Ruang Tunggu',
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            tooltip: 'Sambungkan ulang',
            onPressed: _status == RoomSocketStatus.connected ? null : _reconnect,
            icon: const Icon(Icons.refresh, size: AppIconSize.sm),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space9,
                AppSpacing.space8,
                AppSpacing.space9,
                AppSpacing.space4,
              ),
              child: _heroCard(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space9),
              child: RoomConnectionBar(
                statusColor: _statusColor,
                statusLabel: _statusLabel,
                users: _users,
                onRetry: _status == RoomSocketStatus.disconnected
                    ? _reconnect
                    : null,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Expanded(child: _chatList()),
            RoomComposer(
              controller: _textController,
              enabled: _status == RoomSocketStatus.connected,
              hintText: _status == RoomSocketStatus.connected
                  ? 'Tulis pesan...'
                  : 'Menunggu koneksi...',
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    final quiz = widget.room.quiz;

    return AppHeroCard(
      padding: const EdgeInsets.all(AppSpacing.space9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PIN ROOM', style: AppTextStyles.statLabelOnPrimary),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      formatKode(widget.room.kode),
                      style: AppTextStyles.code.copyWith(
                        color: AppColors.textOnPrimary,
                        fontSize: 34,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: widget.room.status),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            widget.room.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          if (quiz != null && quiz.description.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space2),
            AppHeroSubtitle(quiz.description),
          ],
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
    RoomSocketStatus.connected => 'Tersambung',
    RoomSocketStatus.disconnected => 'Koneksi terputus',
  };

  Widget _chatList() {
    if (_entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.forum_outlined,
              size: AppIconSize.hero,
              color: AppColors.info,
            ),
            const SizedBox(height: AppSpacing.space5),
            Text(
              'Belum ada pesan.',
              style: AppTextStyles.hint.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.space1),
            Text(
              'Sapa pemain lain di room ini.',
              style: AppTextStyles.bodyCaption,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space2,
        AppSpacing.space9,
        AppSpacing.space6,
      ),
      itemCount: _entries.length,
      itemBuilder: (context, index) => _buildEntry(_entries[index]),
    );
  }

  Widget _buildEntry(_ChatEntry entry) {
    final from = entry.from;
    if (from == null) return RoomSystemMessage(text: entry.text);
    return RoomChatBubble(from: from, text: entry.text, mine: entry.mine);
  }
}
