import '../helpers/json.dart';

class ResultEntry {
  final String nama;
  final int skor;

  const ResultEntry({required this.nama, required this.skor});

  factory ResultEntry.fromJson(Map<String, dynamic> json) {
    return ResultEntry(
      nama: jsonString(json['nama']),
      skor: jsonInt(json['skor']),
    );
  }

  Map<String, dynamic> toJson() => {'nama': nama, 'skor': skor};
}

class QuizResult {
  final String id;
  final String roomId;
  final String kode;
  final String quizId;
  final List<ResultEntry> entries;
  final String createdAt;

  const QuizResult({
    required this.id,
    required this.roomId,
    required this.kode,
    required this.quizId,
    required this.entries,
    required this.createdAt,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      id: jsonString(json['id']),
      roomId: jsonString(json['room_id']),
      kode: jsonString(json['kode']),
      quizId: jsonString(json['quiz_id']),
      entries: jsonMapList(json['entries']).map(ResultEntry.fromJson).toList(),
      createdAt: jsonString(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'room_id': roomId,
    'kode': kode,
    'quiz_id': quizId,
    'entries': entries.map((entry) => entry.toJson()).toList(),
    'created_at': createdAt,
  };
}
