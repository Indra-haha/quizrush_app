import '../helpers/json.dart';
import '../models/result.dart';
import 'api_client.dart';

class ResultService {
  ResultService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  ResultService.withApi(this._api);

  static final ResultService instance = ResultService._(ApiClient.instance);

  final ApiClient _api;

  Future<Result> createResult({
    required String token,
    required String kode,
    List<ResultEntry> entries = const [],
  }) async {
    final response = await _api.post(
      '/api/room/$kode/result',
      token: token,
      body: {'entries': entries.map((e) => e.toJson()).toList()},
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 201) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Result.fromJson(jsonMap(data['result']));
  }

  Future<Result> getResult({
    required String token,
    required String kode,
  }) async {
    final response = await _api.get('/api/room/$kode/result', token: token);
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Result.fromJson(jsonMap(data['result']));
  }

  Future<Result> updateResult({
    required String token,
    required String kode,
    required List<ResultEntry> entries,
  }) async {
    final response = await _api.put(
      '/api/room/$kode/result',
      token: token,
      body: {'entries': entries.map((e) => e.toJson()).toList()},
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Result.fromJson(jsonMap(data['result']));
  }

  Future<List<Result>> getAllResults(String token) async {
    final response = await _api.get('/api/results', token: token);
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return jsonMapList(
      data['results'],
    ).map(Result.fromJson).toList();
  }
}
