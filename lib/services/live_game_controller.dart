import 'dart:async';

import 'package:flutter/foundation.dart';

import '../engine/kalkulator_engine.dart';
import '../helpers/json.dart';
import '../models/live_game.dart';
import '../models/room_message.dart';
import 'api/game_service.dart';
import 'api/room_socket.dart';

/// Fase permainan live di sisi klien.
enum LivePhase { waiting, question, pause, ended }

/// Mengelola satu sesi permainan live dari sudut pandang satu peserta:
/// menyimak pesan WS (`question`/`round_result`/`game_end`), menjalankan timer
/// per soal, menghitung skor lewat [KalkulatorEngine], dan mengirim tiap
/// jawaban ke server. Halaman hanya merender state.
class LiveGameController extends ChangeNotifier {
  LiveGameController({
    required this.socket,
    required this.roomKode,
    required this.loginToken,
    required this.myUsername,
    this.isHost = false,
    GameService? gameService,
    LiveQuestion? initialQuestion,
  }) : _game = gameService ?? GameService.instance {
    _sub = socket.messages.listen(_onMessage);
    if (initialQuestion != null) _applyQuestion(initialQuestion);
  }

  final RoomSocket socket;
  final String roomKode;
  final String loginToken;
  final String myUsername;

  /// True bila pengguna ini host (pemilik kuis): tidak menjawab soal dan
  /// tidak mengirim skor — host hanya memantau permainan.
  final bool isHost;
  final GameService _game;

  StreamSubscription<RoomMessage>? _sub;
  Timer? _ticker;
  final Stopwatch _stopwatch = Stopwatch();

  LivePhase _phase = LivePhase.waiting;
  LiveQuestion? _question;
  int? _selectedIndex;
  bool _answered = false;
  bool? _isCorrect;
  int _gainedScore = 0;
  int _totalScore = 0;
  int _correctCount = 0;
  int _answeredCount = 0;
  int _timeLeft = 0;
  double _maxDuration = 0;
  LiveRoundResult? _roundResult;
  LiveGameEnd? _gameEnd;
  List<LiveLeaderboardEntry> _lastLeaderboard = const [];

  LivePhase get phase => _phase;
  LiveQuestion? get question => _question;
  int? get selectedIndex => _selectedIndex;
  bool get answered => _answered;
  bool? get isCorrect => _isCorrect;
  int get gainedScore => _gainedScore;
  int get totalScore => _totalScore;
  int get correctCount => _correctCount;
  int get answeredCount => _answeredCount;
  int get timeLeft => _timeLeft;
  LiveRoundResult? get roundResult => _roundResult;
  LiveGameEnd? get gameEnd => _gameEnd;

  /// Papan peringkat terakhir yang diterima (dari `round_result` /
  /// `game_end`); bertahan antar soal agar view host bisa menampilkan
  /// peringkat sementara selama sesi berjalan.
  List<LiveLeaderboardEntry> get lastLeaderboard => _lastLeaderboard;

  /// Apakah soal aktif soal terakhir.
  bool get isLastQuestion {
    final q = _question;
    return q != null && q.total > 0 && q.index >= q.total - 1;
  }

  void _onMessage(RoomMessage message) {
    switch (message.type) {
      case 'question':
        _applyQuestion(LiveQuestion.fromJson(jsonMap(message.data)));
      case 'round_result':
        _ticker?.cancel();
        _roundResult = LiveRoundResult.fromJson(jsonMap(message.data));
        _lastLeaderboard = _roundResult!.leaderboard;
        _phase = LivePhase.pause;
        notifyListeners();
      case 'game_end':
        _ticker?.cancel();
        _stopwatch.stop();
        _gameEnd = LiveGameEnd.fromJson(jsonMap(message.data));
        _lastLeaderboard = _gameEnd!.leaderboard;
        _phase = LivePhase.ended;
        notifyListeners();
      default:
        break;
    }
  }

  void _applyQuestion(LiveQuestion question) {
    _question = question;
    _maxDuration = question.duration > 0 ? question.duration : 10;
    _timeLeft = _maxDuration.ceil();
    _selectedIndex = null;
    _answered = false;
    _isCorrect = null;
    _gainedScore = 0;
    _roundResult = null;
    _phase = LivePhase.question;
    _stopwatch
      ..reset()
      ..start();
    _startTicker();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
      final left = (_maxDuration - elapsedSeconds).ceil();
      if (left <= 0) {
        _timeLeft = 0;
        // Batalkan ticker dulu: bagi host answer() langsung return, jadi
        // tanpa pembatalan ini timer akan terus berbunyi tiap 100 ms.
        _ticker?.cancel();
        answer(-1);
        return;
      }
      if (left != _timeLeft) {
        _timeLeft = left;
        notifyListeners();
      }
    });
  }

  /// Menjawab soal aktif. `index` di luar rentang berarti waktu habis.
  /// Host tidak menjawab: server menolak jawaban host, jadi tidak ada
  /// perhitungan maupun pengiriman skor.
  void answer(int index) {
    final question = _question;
    if (question == null || _answered || isHost) return;

    _ticker?.cancel();
    _stopwatch.stop();

    final isCorrect = index == question.correctIdx;
    final elapsedMs = _stopwatch.elapsedMilliseconds;
    final gained = KalkulatorEngine.hitungSkorWaktu(
      isBenar: isCorrect,
      elapsedMs: elapsedMs,
      maxDurationSec: _maxDuration.toInt(),
      bobotMaks: question.maxScore > 0 ? question.maxScore : 50,
    );

    _selectedIndex = index;
    _answered = true;
    _isCorrect = isCorrect;
    _gainedScore = gained;
    _totalScore += gained;
    _answeredCount++;
    if (isCorrect) _correctCount++;
    notifyListeners();

    _submit(question, index, isCorrect, elapsedMs, gained);
  }

  Future<void> _submit(
    LiveQuestion question,
    int index,
    bool isCorrect,
    int elapsedMs,
    int score,
  ) async {
    try {
      await _game.submitAnswer(
        token: loginToken,
        kode: roomKode,
        questionIndex: question.index,
        selectedIdx: index,
        isCorrect: isCorrect,
        elapsedMs: elapsedMs,
        score: score,
      );
    } catch (_) {
      // Server tetap otoritatif atas akumulasi/papan peringkat; kegagalan satu
      // kiriman tidak menghentikan permainan.
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }
}
