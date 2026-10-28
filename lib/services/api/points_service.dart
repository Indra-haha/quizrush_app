import '../../helpers/json.dart';
import '../../models/points.dart';
import 'api_client.dart';

/// Klien saldo poin dan riwayat koin user.
class PointsService {
  PointsService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  PointsService.withApi(this._api);

  static final PointsService instance = PointsService._(ApiClient.instance);

  final ApiClient _api;

  /// Ambil total poin dan riwayat dari GET /api/me/points.
  Future<PointsResponse> fetchPointsDetail({required String token}) async {
    final response = await _api.get('/api/me/points', token: token);
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data, statusCode: response.statusCode),
        statusCode: response.statusCode,
      );
    }
    return PointsResponse.fromJson(jsonMap(data));
  }

  /// Kompatibel dengan pemanggil lama; mengembalikan total poin saja.
  Future<int> fetchPoints({required String token}) async {
    final detail = await fetchPointsDetail(token: token);
    return detail.points;
  }
}

