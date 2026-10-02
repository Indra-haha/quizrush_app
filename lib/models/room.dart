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
      id: json['id'] as String? ?? '',
      quizId: json['quiz_id'] as String? ?? '',
      kode: json['kode'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
      judul: json['judul'] as String?,
      isi: json['isi'] as String?,
      quiz: json['quiz'] == null
          ? null
          : QuizSummary.fromJson((json['quiz'] as Map).cast<String, dynamic>()),
    );
  }
}
