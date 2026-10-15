import '../helpers/json.dart';
import 'quiz.dart';

/// Status room sebelum dan sesudah aksi publish. Dikembalikan dari halaman
/// detail room ke halaman daftar room supaya pemanggil tahu apa yang berubah,
/// tanpa harus melakukan request kedua kali.
typedef PublishResult = ({String previous, String next});

class Room {
  final String id;
  final String quizId;
  final String kode;
  final String status;
  final String createdAt;
  final String? judul;
  final String? isi;
  final QuizSummary? quiz;

  const Room({
    required this.id,
    required this.quizId,
    required this.kode,
    required this.status,
    required this.createdAt,
    this.judul,
    this.isi,
    this.quiz,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: jsonString(json['id']),
      quizId: jsonString(json['quiz_id']),
      kode: jsonString(json['kode']),
      status: jsonString(json['status']),
      createdAt: jsonString(json['created_at']),
      judul: jsonStringOrNull(json['judul']),
      isi: jsonStringOrNull(json['isi']),
      quiz: jsonObject(json['quiz'], QuizSummary.fromJson),
    );
  }

  /// Judul yang ditampilkan ke pengguna: `judul` room, jatuh ke judul kuis,
  /// lalu default generik.
  String get displayTitle {
    if (judul?.isNotEmpty ?? false) return judul!;
    final quizTitle = quiz?.title;
    if (quizTitle != null && quizTitle.isNotEmpty) return quizTitle;
    return 'Room Kuis';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quiz_id': quizId,
      'kode': kode,
      'status': status,
      'created_at': createdAt,
      'judul': judul,
      'isi': isi,
      'quiz': quiz?.toJson(),
    };
  }
}
