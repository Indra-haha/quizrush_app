import 'dart:async';

import '../engine/kalkulator_engine.dart';
import '../models/quiz.dart';

/// Logika permainan quiz: timer per soal, pemilihan jawaban, dan akumulasi
/// skor lewat [KalkulatorEngine].
///
/// Dipisah dari widget supaya halaman test hanya merender state. Kelas ini
/// murni Dart (tanpa Flutter) dan bisa diuji tanpa pump widget.
class QuizPlaySession {
  QuizPlaySession({
    required this.questions,
    this.correctIndex = 0,
    this.feedbackDelay = const Duration(seconds: 3),
    this.defaultDuration = 12.0,
  });

  final List<QuizQuestion> questions;

  /// Indeks jawaban yang dianggap benar. Halaman test lokal selalu memakai 0.
  final int correctIndex;

  /// Jeda sebelum pindah ke soal berikutnya supaya banner hasil terbaca.
  final Duration feedbackDelay;

  /// Durasi fallback kalau soal tidak punya durasi.
  final double defaultDuration;

  /// Dipanggil setiap state berubah supaya widget bisa `setState`.
  void Function()? onChanged;

  /// Dipanggil sekali setelah soal terakhir dijawab.
  void Function()? onFinished;

  int _currentIndex = 0;
  int _totalScore = 0;
  int _timeLeft = 0;
  double _maxDuration = 12.0;
  int? _selectedAnswerIndex;
  bool _isAnswered = false;
  bool? _isUserCorrect;
  int _gainedScore = 0;

  Timer? _ticker;
  Timer? _advance;
  final Stopwatch _stopwatch = Stopwatch();

  int get currentIndex => _currentIndex;
  int get totalScore => _totalScore;
  int get timeLeft => _timeLeft;
  double get maxDuration => _maxDuration;
  int? get selectedAnswerIndex => _selectedAnswerIndex;
  bool get isAnswered => _isAnswered;
  bool? get isUserCorrect => _isUserCorrect;
  int get gainedScore => _gainedScore;
  int get totalQuestions => questions.length;
  bool get isEmpty => questions.isEmpty;

  QuizQuestion get currentQuestion => questions[_currentIndex];

  /// Poin maksimum soal aktif, minimal 50 kalau kuis tidak mengisinya.
  int get currentMaxScore {
    final skor = currentQuestion.skor;
    return skor > 0 ? skor : 50;
  }

  void start() {
    if (questions.isEmpty) return;

    final duration = currentQuestion.duration > 0
        ? currentQuestion.duration
        : defaultDuration;
    _maxDuration = duration;
    _timeLeft = duration.toInt();

    _stopwatch
      ..reset()
      ..start();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_timeLeft > 0) {
        final elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
        _timeLeft = (_maxDuration - elapsedSeconds).ceil();
        if (_timeLeft < 0) _timeLeft = 0;
        _notify();
      } else {
        answer(-1);
      }
    });
  }

  /// Menjawab soal. `index` di luar rentang pilihan berarti waktu habis.
  void answer(int index) {
    if (_isAnswered) return;
    _ticker?.cancel();
    _stopwatch.stop();

    final isCorrect = index == correctIndex;
    final gained = KalkulatorEngine.hitungSkorWaktu(
      isBenar: isCorrect,
      elapsedMs: _stopwatch.elapsedMilliseconds,
      maxDurationSec: _maxDuration.toInt(),
      bobotMaks: currentMaxScore,
    );

    _selectedAnswerIndex = index;
    _isAnswered = true;
    _isUserCorrect = isCorrect;
    _gainedScore = gained;
    if (gained > 0) _totalScore += gained;
    _notify();

    _advance?.cancel();
    _advance = Timer(feedbackDelay, advance);
  }

  /// Lanjut ke soal berikutnya, atau tandai sesi selesai.
  void advance() {
    if (_currentIndex < questions.length - 1) {
      _currentIndex++;
      _selectedAnswerIndex = null;
      _isAnswered = false;
      _isUserCorrect = null;
      _gainedScore = 0;
      _notify();
      start();
    } else {
      _ticker?.cancel();
      onFinished?.call();
    }
  }

  void dispose() {
    _ticker?.cancel();
    _advance?.cancel();
    _stopwatch.stop();
  }

  void _notify() => onChanged?.call();
}
