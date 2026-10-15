import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../helpers/json.dart';
import '../helpers/quiz_image.dart';
import '../models/quiz.dart';
import 'api_client.dart';

class QuizService {
  QuizService._();
  static final QuizService instance = QuizService._();

  Future<AllQuizzes> getQuizzes(String token) async {
    final response = await http
        .get(
          Uri.parse('${ApiClient.baseUrl}/api/quizzes'),
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
    return AllQuizzes.fromJson(jsonMap(data));
  }

  Future<MyQuizzes> getMyQuizzes(String token) async {
    final response = await http
        .get(
          Uri.parse('${ApiClient.baseUrl}/api/my-quizzes'),
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
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiClient.baseUrl}/api/create/quiz'),
    );
    request.headers.addAll(ApiClient.headers(token: token));
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

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);
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
