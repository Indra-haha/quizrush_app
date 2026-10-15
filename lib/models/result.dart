import '../helpers/json.dart';
import 'quiz.dart';

class Result {
  final String id;
  final String roomId;
  final String kode;
  final String quizId;
  final String createdAt;
  final QuizSummary? quiz;
  final List<ResultEntry> entries;

  const Result({
    required this.id,
    required this.roomId,
    required this.kode,
    required this.quizId,
    required this.createdAt,
    this.quiz,
    this.entries = const [],
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    return Result(
      id: jsonString(json['id']),
      roomId: jsonString(json['room_id']),
      kode: jsonString(json['kode']),
      quizId: jsonString(json['quiz_id']),
      createdAt: jsonString(json['created_at']),
      quiz: jsonObject(json['quiz'], QuizSummary.fromJson),
      entries: jsonMapList(
        json['entries'],
      ).map(ResultEntry.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'kode': kode,
      'quiz_id': quizId,
      'created_at': createdAt,
      'quiz': quiz?.toJson(),
      'entries': entries.map((e) => e.toJson()).toList(),
    };
  }
}

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

  Map<String, dynamic> toJson() {
    return {'nama': nama, 'skor': skor};
  }
}
