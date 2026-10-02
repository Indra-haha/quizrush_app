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
      id: json['id'] as String? ?? '',
      roomId: json['room_id'] as String? ?? '',
      kode: json['kode'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      quiz: json['quiz'] == null
          ? null
          : QuizSummary.fromJson((json['quiz'] as Map).cast<String, dynamic>()),
      entries: (json['entries'] as List? ?? [])
          .map((e) => ResultEntry.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }
}

class ResultEntry {
  final String nama;
  final int skor;

  const ResultEntry({required this.nama, required this.skor});

  factory ResultEntry.fromJson(Map<String, dynamic> json) {
    return ResultEntry(
      nama: json['nama'] as String? ?? '',
      skor: json['skor'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'nama': nama, 'skor': skor};
  }
}
