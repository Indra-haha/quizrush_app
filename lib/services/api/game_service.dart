import '../../helpers/json.dart';
import '../../models/live_game.dart';
import 'api_client.dart';

/// Klien endpoint permainan live.
///
/// Skor per soal dihitung di klien (lihat [KalkulatorEngine]) lalu dikirim ke
/// server lewat `POST /api/room/{kode}/answer`; server memakainya dengan
/// penjagaan ringan dan mengakumulasi skor.
class GameService {
  GameService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  GameService.withApi(this._api);

  static final GameService instance = GameService._(ApiClient.instance);

  final ApiClient _api;

  Future<SubmitAnswerResult> submitAnswer({
    required String token,
    required String kode,
    required int questionIndex,
    required int selectedIdx,
    required bool isCorrect,
    required int elapsedMs,
    required int score,
  }) async {
    final response = await _api.post(
      '/api/room/$kode/answer',
      token: token,
      body: {
        'question_index': questionIndex,
        'selected_idx': selectedIdx,
        'is_correct': isCorrect,
        'elapsed_ms': elapsedMs,
        'score': score,
      },
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return SubmitAnswerResult.fromJson(jsonMap(data));
  }
}
