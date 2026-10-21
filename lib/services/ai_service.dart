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

  /// Status yang menandakan provider AI sedang sibuk/transien, bukan kesalahan
  /// permintaan klien. Nilai ini dicoba ulang sekali lalu diberi pesan khusus.
  static const Set<int> transientStatuses = {502, 503, 504};

  /// Jeda sebelum mencoba ulang saat provider sibuk.
  static const Duration retryDelay = Duration(milliseconds: 1200);

  /// Batas percobaan untuk status transien (1 percobaan awal + 1 ulangan).
  static const int maxAttempts = 2;

  final ApiClient _api;

  /// Minta model AI membuatkan daftar soal dari [topic] (topik/ide teks bebas).
  ///
  /// Jumlah soal ditentukan oleh server/model dari isi [topic]; hasil yang
  /// tidak valid (opsi tidak berjumlah 4, dsb.) dibuang, bukan dilempar error.
  /// Status transien ([transientStatuses]) dicoba ulang sekali karena provider
  /// AI kerap membalas 503/504 sesaat.
  Future<List<QuizQuestionInput>> suggestQuestions({
    required String token,
    required String topic,
  }) async {
    for (var attempt = 1; ; attempt++) {
      try {
        return await _requestSuggestions(token: token, topic: topic);
      } on ApiException catch (e) {
        final canRetry =
            attempt < maxAttempts && transientStatuses.contains(e.statusCode);
        if (!canRetry) rethrow;
        await Future<void>.delayed(retryDelay);
      }
    }
  }

  Future<List<QuizQuestionInput>> _requestSuggestions({
    required String token,
    required String topic,
  }) async {
    final response = await _api.post(
      suggestPath,
      token: token,
      body: {'topic': topic},
      timeout: const Duration(seconds: 90),
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        transientStatuses.contains(response.statusCode)
            ? 'Model AI sedang sibuk. Coba lagi sebentar lagi.'
            : ApiClient.message(data, statusCode: response.statusCode),
        statusCode: response.statusCode,
      );
    }
    final raw = data is Map ? data['questions'] : null;
    return jsonMapList(
      raw,
    ).map(_parseQuestion).whereType<QuizQuestionInput>().toList();
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
