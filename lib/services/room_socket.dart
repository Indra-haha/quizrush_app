import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';

import '../models/room_message.dart';
import 'api_client.dart';
import 'device_service.dart';

/// Status koneksi WebSocket room, dipakai halaman ruang tunggu untuk
/// menampilkan indikator "menyambung / tersambung / koneksi terputus".
enum RoomSocketStatus { connecting, connected, reconnecting, disconnected }

/// Klien WebSocket ruang tunggu (lobby) sesuai API.md §8.1:
///
/// * handshake `GET /api/rooms?token=<JWT room>&name=<nama>` (scheme `http`→
///   `ws`, `https`→`wss`) dengan header `Authorization: Bearer <JWT login>`
///   **dan** `User-Agent` smartphone agar lolos `middleware.DeviceLabel`;
/// * pesan ber-envelope `{type, room, from, time, data, users}`;
/// * ping/pong level-protocol ditangani otomatis oleh `dart:io` WebSocket;
/// * reconnect otomatis dengan backoff ketika koneksi putus di luar kendali
///   pengguna — [dispose] menghentikan semuanya.
class RoomSocket {
  RoomSocket({
    required this.roomToken,
    required this.loginToken,
    this.name = '',
    this.maxAttempts = 4,
  });

  /// JWT ber-scope room dari `POST /api/rooms/verify`, dikirim sebagai query.
  final String roomToken;

  /// JWT login yang dikirim sebagai header `Authorization`.
  final String loginToken;

  /// `name` query (opsional); kosong → memakai default server (username).
  final String name;

  /// Berapa kali percobaan ulang otomatis sebelum status jadi [RoomSocketStatus.disconnected].
  final int maxAttempts;

  final _messages = StreamController<RoomMessage>.broadcast();
  final _statuses = StreamController<RoomSocketStatus>.broadcast();

  Stream<RoomMessage> get messages => _messages.stream;
  Stream<RoomSocketStatus> get statuses => _statuses.stream;

  IOWebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _reconnectTimer;
  int _attempts = 0;
  bool _disposed = false;

  bool get isConnected => _channel != null;

  /// Buka koneksi (atau buka ulang setelah [RoomSocketStatus.disconnected]).
  void connect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _attempts = 0;
    _open(isRetry: false);
  }

  /// Kirim pesan `broadcast` (API.md §8, "Pesan dari klien"). Pesan ini
  /// dibalikkan server ke klien **lain** di room yang sama, bukan ke pengirim.
  void sendBroadcast(String data) {
    final channel = _channel;
    if (channel == null) return;
    channel.sink.add(jsonEncode({'type': 'broadcast', 'data': data}));
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _sub = null;
    _channel?.sink.close();
    _channel = null;
    _messages.close();
    _statuses.close();
  }

  void _open({required bool isRetry}) {
    if (_disposed) return;
    _statuses.add(
      isRetry
          ? RoomSocketStatus.reconnecting
          : RoomSocketStatus.connecting,
    );

    try {
      final channel = IOWebSocketChannel.connect(
        _handshakeUri(),
        headers: {
          'Authorization': 'Bearer $loginToken',
          'User-Agent': DeviceService.instance.userAgent,
        },
        pingInterval: const Duration(seconds: 30),
      );
      _channel = channel;
      _sub = channel.stream.listen(
        _onData,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _onData(dynamic raw) {
    if (raw is! String) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final message = RoomMessage.fromJson(decoded.cast<String, dynamic>());
      if (message.type == 'connected') {
        _attempts = 0;
        _statuses.add(RoomSocketStatus.connected);
      }
      _messages.add(message);
    } catch (_) {
      // Payload bukan JSON valid — abaikan (server membalas `error`).
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    if (_reconnectTimer?.isActive ?? false) return;
    _sub?.cancel();
    _sub = null;
    _channel = null;

    if (_attempts >= maxAttempts) {
      _statuses.add(RoomSocketStatus.disconnected);
      return;
    }

    final delay = Duration(seconds: 1 << _attempts); // 1s, 2s, 4s, 8s
    _attempts++;
    _statuses.add(RoomSocketStatus.reconnecting);
    _reconnectTimer = Timer(delay, () => _open(isRetry: true));
  }

  Uri _handshakeUri() {
    final base = Uri.parse(ApiClient.instance.baseUrl);
    return Uri(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      host: base.host,
      // Dart's `Uri` only knows default ports for http/https, so a `wss` URI
      // without an explicit port resolves to port 0 and the handshake goes to
      // `https://host:0/...` (rejected 400). Always pass the real port.
      port: base.port, // http -> 80, https -> 443, atau port eksplisit
      path: '/api/rooms',
      queryParameters: {
        'token': roomToken,
        if (name.isNotEmpty) 'name': name,
      },
    );
  }
}
