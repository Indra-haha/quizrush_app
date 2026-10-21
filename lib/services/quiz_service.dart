import 'package:http/http.dart' as http;

import '../helpers/json.dart';
import '../helpers/quiz_image.dart';
import '../models/quiz.dart';
import 'api_client.dart';

/// Tahap proses unggah gambar kuis, dilaporkan ke UI sebagai progres.
enum QuizImageUploadStage {
  requestingSignature('Minta signature ke server…'),
  uploading('Mengunggah ke Cloudinary…');

  const QuizImageUploadStage(this.label);

  /// Teks singkat tahap untuk ditampilkan pada overlay gambar.
  final String label;
}

/// Identitas aset gambar kuis di Cloudinary: URL `path` (secure_url).
/// Dikirim ke server sebagai `path` saat membuat kuis.
class QuizImageAsset {
  const QuizImageAsset({required this.path});

  final String path;
}

/// Hasil endpoint `POST /api/create/signature` (§4.2) untuk upload langsung
/// ke Cloudinary.
class _CloudinarySignature {
  const _CloudinarySignature({
    required this.signature,
    required this.timestamp,
    required this.apiKey,
    required this.cloudName,
  });

  final String signature;
  final int timestamp;
  final String apiKey;
  final String cloudName;

  factory _CloudinarySignature.fromJson(Map<String, dynamic> json) {
    final signature = json['signature'];
    final apiKey = json['apiKey'] ?? json['api_key'];
    final cloudName = json['cloudName'] ?? json['cloud_name'];
    if (signature is! String ||
        signature.isEmpty ||
        apiKey is! String ||
        apiKey.isEmpty ||
        cloudName is! String ||
        cloudName.isEmpty) {
      throw const FormatException('Field signature tidak lengkap');
    }
    final timestamp = json['timestamp'];
    final int parsedTimestamp;
    if (timestamp is num) {
      parsedTimestamp = timestamp.toInt();
    } else if (timestamp is String) {
      parsedTimestamp = int.parse(timestamp);
    } else {
      throw const FormatException('timestamp tidak valid');
    }
    return _CloudinarySignature(
      signature: signature,
      timestamp: parsedTimestamp,
      apiKey: apiKey,
      cloudName: cloudName,
    );
  }
}

class QuizService {
  QuizService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  QuizService.withApi(this._api);

  static final QuizService instance = QuizService._(ApiClient.instance);

  /// Folder tujuan aset gambar kuis di Cloudinary (§4.2).
  static const String quizImageFolder = 'galery-quiz/quiz-image';

  static const String _cloudinaryHost = 'api.cloudinary.com';

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

  /// Unggah gambar kuis ke Cloudinary (§4.2–§4.3) dan kembalikan URL
  /// aset (`secure_url`) yang akan dikirim sebagai `path` pada [createQuiz].
  ///
  /// [onStage] dipanggil di awal setiap tahap agar UI bisa menampilkan
  /// progresnya.
  Future<QuizImageAsset> uploadQuizImage({
    required String token,
    required List<int> imageBytes,
    required String imageFilename,
    void Function(QuizImageUploadStage stage)? onStage,
  }) async {
    onStage?.call(QuizImageUploadStage.requestingSignature);
    final signature = await _requestSignature(token);
    onStage?.call(QuizImageUploadStage.uploading);
    return _uploadToCloudinary(
      signature: signature,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
    );
  }

  Future<Quizes> createQuiz({
    required String token,
    required String title,
    String? description,
    required List<QuizQuestionInput> questions,
    required String path,
  }) async {
    final response = await _api.post(
      '/api/create/quiz',
      token: token,
      body: {
        'title': title,
        'description': description,
        'path': path,
        'questions': questions.map((q) => q.toJson()).toList(),
      },
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

  /// Minta signature Cloudinary ke server (§4.2).
  Future<_CloudinarySignature> _requestSignature(String token) async {
    final response = await _api.post(
      '/api/create/signature',
      token: token,
      body: {'folder': quizImageFolder},
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }
    try {
      return _CloudinarySignature.fromJson(jsonMap(data));
    } catch (_) {
      throw const ApiException('Respons signature tidak valid');
    }
  }

  /// Unggah gambar langsung ke Cloudinary (§4.3), kembalikan URL aset
  /// (`secure_url`).
  Future<QuizImageAsset> _uploadToCloudinary({
    required _CloudinarySignature signature,
    required List<int> imageBytes,
    required String imageFilename,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(
        'https://$_cloudinaryHost/v1_1/${signature.cloudName}/image/upload',
      ),
    );
    request.fields['api_key'] = signature.apiKey;
    request.fields['timestamp'] = '${signature.timestamp}';
    request.fields['signature'] = signature.signature;
    request.fields['folder'] = quizImageFolder;
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
      timeout: const Duration(seconds: 60),
    );
    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _cloudinaryMessage(data),
        statusCode: response.statusCode,
      );
    }
    final secureUrl = data['secure_url'];
    if (secureUrl is! String || secureUrl.isEmpty) {
      throw const ApiException('Respons Cloudinary tidak valid');
    }
    return QuizImageAsset(path: secureUrl);
  }

  /// Pesan error Cloudinary berbentuk `{"error":{"message":"..."}}`.
  static String _cloudinaryMessage(dynamic data) {
    if (data is Map && data['error'] is Map) {
      final message = data['error']['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return ApiClient.message(data);
  }
}
