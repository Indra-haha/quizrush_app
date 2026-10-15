/// Validasi form buat kuis. Murni dan tanpa UI supaya mudah diuji.
library;

/// Satu pertanyaan yang sudah dibaca dari form.
class QuizFormQuestion {
  final String question;
  final List<String> options;
  final int? correctIdx;
  final String skor;

  const QuizFormQuestion({
    required this.question,
    required this.options,
    required this.correctIdx,
    required this.skor,
  });
}

class QuizFormValidator {
  QuizFormValidator._();

  static const int minQuestions = 5;
  static const int minSkor = 1;
  static const int maxSkor = 50;

  /// Pesan error pertama, atau `null` kalau form valid.
  static String? validate({
    required String title,
    required String description,
    required bool hasImage,
    required List<QuizFormQuestion> questions,
  }) {
    if (title.trim().isEmpty) return 'Judul quiz wajib diisi.';
    if (description.trim().isEmpty) return 'Deskripsi quiz wajib diisi.';
    if (!hasImage) return 'Gambar kuis wajib diunggah.';
    if (questions.length < minQuestions) {
      return 'Minimal $minQuestions pertanyaan.';
    }

    for (var i = 0; i < questions.length; i++) {
      final question = questions[i];
      if (question.question.trim().isEmpty) {
        return 'Pertanyaan ${i + 1} wajib diisi.';
      }
      for (var j = 0; j < question.options.length; j++) {
        if (question.options[j].trim().isEmpty) {
          return 'Jawaban ${j + 1} pada pertanyaan ${i + 1} wajib diisi.';
        }
      }
      if (question.correctIdx == null) {
        return 'Pilih jawaban benar untuk pertanyaan ${i + 1}.';
      }
      final skor = int.tryParse(question.skor.trim());
      if (skor == null || skor < minSkor || skor > maxSkor) {
        return 'Poin pertanyaan ${i + 1} harus berupa angka $minSkor-$maxSkor.';
      }
    }
    return null;
  }
}
