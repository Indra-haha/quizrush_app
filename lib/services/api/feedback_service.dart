import '../../helpers/json.dart';
import '../../models/feedback.dart';
import 'api_client.dart';

/// Service untuk berinteraksi dengan endpoint publik POST /api/feedback (§16.1).
///
/// Menyediakan pengiriman kritik & saran pengguna tanpa memerlukan login JWT
/// maupun allowlist perangkat.
class FeedbackService {
  FeedbackService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  FeedbackService.withApi(this._api);

  static final FeedbackService instance = FeedbackService._(ApiClient.instance);

  final ApiClient _api;

  /// Mengirim feedback (saran & kesan) ke POST /api/feedback (§16.1).
  ///
  /// Response `201 Created`: [FeedbackResponse] yang memuat `message` dan objek `feedback`.
  /// Bila gagal (HTTP 400, 413, 415, 500), melemparkan [ApiException].
  Future<FeedbackResponse> sendFeedback({
    required String username,
    required String saran,
    required String kesan,
    String? token,
  }) async {
    final trimmedUsername = username.trim();
    final trimmedSaran = saran.trim();
    final trimmedKesan = kesan.trim();

    if (trimmedUsername.isEmpty) {
      throw const ApiException('username wajib diisi', statusCode: 400);
    }
    if (trimmedSaran.isEmpty) {
      throw const ApiException('saran wajib diisi', statusCode: 400);
    }
    if (trimmedKesan.isEmpty) {
      throw const ApiException('kesan wajib diisi', statusCode: 400);
    }

    final payload = FeedbackRequest(
      username: trimmedUsername,
      saran: trimmedSaran,
      kesan: trimmedKesan,
    );

    final response = await _api.post(
      '/api/feedback',
      token: token,
      body: payload.toJson(),
    );

    final data = ApiClient.decode(response);
    if (response.statusCode != 201) {
      throw ApiException(
        ApiClient.message(data, statusCode: response.statusCode),
        statusCode: response.statusCode,
      );
    }

    return FeedbackResponse.fromJson(jsonMap(data));
  }

  /// Mengirim objek [FeedbackRequest] langsung.
  Future<FeedbackResponse> postFeedback(
    FeedbackRequest request, {
    String? token,
  }) {
    return sendFeedback(
      username: request.username,
      saran: request.saran,
      kesan: request.kesan,
      token: token,
    );
  }
}
