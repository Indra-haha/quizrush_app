import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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
    return AllQuizzes.fromJson((data as Map).cast<String, dynamic>());
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
    return MyQuizzes.fromJson((data as Map).cast<String, dynamic>());
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
        contentType: _imageMediaType(imageFilename),
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
    return Quizes.fromJson((data['quiz'] as Map).cast<String, dynamic>());
  }

  MediaType _imageMediaType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}
