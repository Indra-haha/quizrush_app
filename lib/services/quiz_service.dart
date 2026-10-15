import 'dart:convert';

import 'package:http/http.dart' as http;

import '../helpers/json.dart';
import '../helpers/quiz_image.dart';
import '../models/quiz.dart';
import 'api_client.dart';

class QuizService {
  QuizService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  QuizService.withApi(this._api);

  static final QuizService instance = QuizService._(ApiClient.instance);

  final ApiClient _api;

  Future<AllQuizzes> getQuizzes(String token) async {
    final response = await _api.get('/api/quizzes', token: token);
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return AllQuizzes.fromJson(jsonMap(data));
  }

  Future<MyQuizzes> getMyQuizzes(String token) async {
    final response = await _api.get('/api/my-quizzes', token: token);
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return MyQuizzes.fromJson(jsonMap(data));
  }

  Future<Quizes> createQuiz({
    required String token,
    required String title,
    String? description,
    required List<QuizQuestionInput> questions,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    final request = http.MultipartRequest('POST', _api.uri('/api/create/quiz'));
    request.headers.addAll(_api.headers(token: token));
    request.fields['data'] = jsonEncode({
      'title': title,
      'description': ?description,
      'questions': questions.map((q) => q.toJson()).toList(),
    });
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: imageFilename,
        contentType: QuizImage.mediaType(imageFilename),
      ),
    );

    final response = await _api.send(
      request,
      timeout: const Duration(seconds: 30),
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 201) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    return Quizes.fromJson(jsonMap(data['quiz']));
  }
}
