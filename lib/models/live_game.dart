import '../helpers/json.dart';

/// Soal live yang disiarkan server lewat WebSocket (`type: "question"`).
///
/// Server mengirim `correct_idx` karena skor dihitung klien (dengan penjagaan
/// ringan di server), jadi klien perlu tahu kunci untuk menentukan benar/salah.
class LiveQuestion {
  final int index;
  final int total;
  final String question;
  final List<String> options;
  final int correctIdx;
  final double duration;
  final int maxScore;
  final int expiresAt;

  const LiveQuestion({
    required this.index,
    required this.total,
    required this.question,
    required this.options,
    required this.correctIdx,
    required this.duration,
    required this.maxScore,
    this.expiresAt = 0,
  });

  factory LiveQuestion.fromJson(Map<String, dynamic> json) {
    return LiveQuestion(
      index: jsonInt(json['index']),
      total: jsonInt(json['total']),
      question: jsonString(json['question']),
      options: jsonStringList(json['options']),
      correctIdx: jsonInt(json['correct_idx']),
      duration: jsonDouble(json['duration']),
      maxScore: jsonInt(json['max_score']),
      expiresAt: jsonInt(json['expires_at']),
    );
  }
}

/// Satu baris papan peringkat.
class LiveLeaderboardEntry {
  final int rank;
  final String username;
  final String nama;
  final int score;
  final int correct;
  final int answered;

  const LiveLeaderboardEntry({
    required this.rank,
    required this.username,
    required this.nama,
    required this.score,
    required this.correct,
    required this.answered,
  });

  factory LiveLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LiveLeaderboardEntry(
      rank: jsonInt(json['rank']),
      username: jsonString(json['username']),
      nama: jsonString(json['nama']),
      score: jsonInt(json['score']),
      correct: jsonInt(json['correct']),
      answered: jsonInt(json['answered']),
    );
  }

  /// Nama tampilan: nama lengkap, jatuh ke username.
  String get displayName => nama.isNotEmpty ? nama : username;

  /// Persentase jawaban benar.
  double get accuracy => answered > 0 ? correct / answered : 0;
}

/// Hasil satu ronde (`type: "round_result"`), dipakai papan jeda.
class LiveRoundResult {
  final int round;
  final int total;
  final int correctIdx;
  final int nextInMs;
  final List<LiveLeaderboardEntry> leaderboard;

  const LiveRoundResult({
    required this.round,
    required this.total,
    required this.correctIdx,
    required this.nextInMs,
    required this.leaderboard,
  });

  factory LiveRoundResult.fromJson(Map<String, dynamic> json) {
    return LiveRoundResult(
      round: jsonInt(json['round']),
      total: jsonInt(json['total']),
      correctIdx: jsonInt(json['correct_idx']),
      nextInMs: jsonInt(json['next_in_ms']),
      leaderboard: jsonMapList(
        json['leaderboard'],
      ).map(LiveLeaderboardEntry.fromJson).toList(),
    );
  }
}

/// Akhir permainan (`type: "game_end"`).
class LiveGameEnd {
  final int total;
  final List<LiveLeaderboardEntry> leaderboard;
  final String finishedAt;

  const LiveGameEnd({
    required this.total,
    required this.leaderboard,
    required this.finishedAt,
  });

  factory LiveGameEnd.fromJson(Map<String, dynamic> json) {
    return LiveGameEnd(
      total: jsonInt(json['total']),
      leaderboard: jsonMapList(
        json['leaderboard'],
      ).map(LiveLeaderboardEntry.fromJson).toList(),
      finishedAt: jsonString(json['finished_at']),
    );
  }
}

/// Respons POST /api/room/{kode}/answer (akumulasi skor setelah dicatat).
class SubmitAnswerResult {
  final String message;
  final int score;
  final int correct;
  final int answered;

  const SubmitAnswerResult({
    required this.message,
    required this.score,
    required this.correct,
    required this.answered,
  });

  factory SubmitAnswerResult.fromJson(Map<String, dynamic> json) {
    return SubmitAnswerResult(
      message: jsonString(json['message']),
      score: jsonInt(json['score']),
      correct: jsonInt(json['correct']),
      answered: jsonInt(json['answered']),
    );
  }
}
