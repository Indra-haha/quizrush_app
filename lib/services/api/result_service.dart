import '../../helpers/json.dart';
import '../../models/quiz_result.dart';
import 'api_client.dart';

class ResultService {
  ResultService._(this._api);

  ResultService.withApi(this._api);

  static final ResultService instance = ResultService._(ApiClient.instance);

  final ApiClient _api;

  Future<List<QuizResult>> fetchResults({
    required String token,
    int? limit,
    int? skip,
  }) async {
    final query = <String>[
      if (limit != null) 'limit=$limit',
      if (skip != null) 'skip=$skip',
    ];
    final path = '/api/results${query.isEmpty ? '' : '?${query.join('&')}'}';
    final response = await _api.get(path, token: token);
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return jsonMapList(
      jsonMap(data)['results'],
    ).map(QuizResult.fromJson).toList();
  }
}
