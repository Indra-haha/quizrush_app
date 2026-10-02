import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/result.dart';
import 'api_client.dart';

class ResultService {
  ResultService._();
  static final ResultService instance = ResultService._();

  Future<Result> createResult({
    required String token,
    required String kode,
    List<ResultEntry> entries = const [],
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiClient.baseUrl}/api/room/$kode/result'),
          headers: ApiClient.headers(token: token, body: true),
          body: jsonEncode({
            'entries': entries.map((e) => e.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 201) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Result.fromJson((data['result'] as Map).cast<String, dynamic>());
  }

  Future<Result> getResult({
    required String token,
    required String kode,
  }) async {
    final response = await http
        .get(
          Uri.parse('${ApiClient.baseUrl}/api/room/$kode/result'),
          headers: ApiClient.headers(token: token),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Result.fromJson((data['result'] as Map).cast<String, dynamic>());
  }

  Future<Result> updateResult({
    required String token,
    required String kode,
    required List<ResultEntry> entries,
  }) async {
    final response = await http
        .put(
          Uri.parse('${ApiClient.baseUrl}/api/room/$kode/result'),
          headers: ApiClient.headers(token: token, body: true),
          body: jsonEncode({
            'entries': entries.map((e) => e.toJson()).toList(),
          }),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Result.fromJson((data['result'] as Map).cast<String, dynamic>());
  }

  Future<List<Result>> getAllResults(String token) async {
    final response = await http
        .get(
          Uri.parse('${ApiClient.baseUrl}/api/results'),
          headers: ApiClient.headers(token: token),
        )
        .timeout(const Duration(seconds: 10));
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    final list = data['results'] as List;
    return list
        .map((e) => Result.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}
