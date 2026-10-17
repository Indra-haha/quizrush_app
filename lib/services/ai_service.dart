import '../helpers/json.dart';
import '../models/quiz.dart';
import 'api_client.dart';

/// Service untuk saran soal otomatis (AI) via `POST /api/ai/suggest`.
class AiService {
  AiService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  AiService.withApi(this._api);

  static final AiService instance = AiService._(ApiClient.instance);

  /// Path endpoint saran soal AI.
  static const String suggestPath = '/api/ai/suggest';

  /// Durasi yang diizinkan server untuk sebuah soal (§4.4).
  static const List<double> allowedDurations = [1.5, 2.0, 3.0, 5.0];

  final ApiClient _api;

  /// Minta model AI membuatkan daftar soal dari [topic] (topik/ide teks bebas).
  ///
  /// Jumlah soal dikembalikan mengikuti permintaan server/model; hasil yang
  /// tidak valid (opsi tidak berjumlah 4, dsb.) dibuang, bukan dilempar error.
  Future<List<QuizQuestionInput>> suggestQuestions({
    required String token,
    required String topic,
    int count = 5,
  }) async {
    final response = await _api.post(
      suggestPath,
      token: token,
      body: {'topic': topic, 'count': count},
      timeout: const Duration(seconds: 90),
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    final raw = data is Map ? data['questions'] : null;
    return jsonMapList(raw).map(_parseQuestion).whereType<QuizQuestionInput>().toList();
  }

  /// Ubah satu objek JSON hasil AI menjadi [QuizQuestionInput].
  ///
  /// Mengembalikan `null` kalau bentuknya tidak layak dipakai (question
  /// kosong atau options tidak berjumlah 4). Field dengan nilai di luar
  /// aturan server (duration, skor, correct_idx) di-normalisasi ke nilai
  /// default yang aman.
  QuizQuestionInput? _parseQuestion(Map<String, dynamic> json) {
    final question = jsonString(json['question']).trim();
    final options = jsonStringList(json['options']).take(4).toList();
    if (question.isEmpty || options.length != 4) return null;

    final rawDuration = jsonDouble(json['duration'], 2.0);
    final duration = allowedDurations.contains(rawDuration) ? rawDuration : 2.0;

    var correctIdx = jsonInt(json['correct_idx'], 0);
    if (correctIdx < 0 || correctIdx > 3) correctIdx = 0;

    var skor = jsonInt(json['skor'], 10);
    if (skor < 1 || skor > 50) skor = 10;

    return QuizQuestionInput(
      question: question,
      options: options,
      correctIdx: correctIdx,
      duration: duration,
      skor: skor,
    );
  }
}
