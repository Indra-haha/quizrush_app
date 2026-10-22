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

/// Identitas aset gambar kuis di Cloudinary.
///
/// [publicId] dan [format] dikirim ke server sebagai `image_id` dan
/// `image_format` saat membuat kuis, karena server menyusun ulang signed URL
/// berjenuh `authenticated` dari keduanya. [path] menyimpan `secure_url`
/// hasil upload untuk keperluan pratinjau.
class QuizImageAsset {
  const QuizImageAsset({
    required this.publicId,
    required this.format,
    required this.path,
  });

  /// Public ID aset di Cloudinary, tanpa ekstensi.
  final String publicId;

  /// Format aset, misalnya `png` atau `jpg`.
  final String format;

  /// `secure_url` hasil upload.
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
    required this.type,
  });

  final String signature;
  final int timestamp;
  final String apiKey;
  final String cloudName;

  /// Tipe delivery yang ditandatangani server. Wajib dikirim balik saat
  /// upload, karena Cloudinary menghitung hash atas seluruh field form.
  final String type;

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
    final type = json['type'];
    return _CloudinarySignature(
      signature: signature,
      timestamp: parsedTimestamp,
      apiKey: apiKey,
      cloudName: cloudName,
      type: type is String && type.isNotEmpty ? type : _defaultDeliveryType,
    );
  }

  /// Tipe delivery default bila server tidak mengirimkannya.
  static const String _defaultDeliveryType = 'authenticated';
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

  /// Kumpulkan pilihan kategori dari kuis milik user (`GET /api/my-quizzes`).
  ///
  /// `POST /api/create/quiz` belum menerima field kategori, jadi hasil method
  /// ini dipakai untuk mengisi dropdown pada form create quiz saja.
  Future<List<String>> fetchKategoriOptions({required String token}) async {
    final quizzes = await getMyQuizzes(token);
    final values = <String>{Quizes.defaultKategori};
    for (final quiz in quizzes.all) {
      values.add(quiz.kategoriLabel);
    }
    final options = values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return options;
  }

  /// Unggah gambar kuis ke Cloudinary (§4.2–§4.3) dan kembalikan identitas
  /// aset ([QuizImageAsset]).
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

  /// Buat kuis baru (§4.4). [imageId] dan [imageFormat] berasal dari aset
  /// gambar yang sudah terunggah ke Cloudinary.
  Future<Quizes> createQuiz({
    required String token,
    required String title,
    String? description,
    required List<QuizQuestionInput> questions,
    required String imageId,
    required String imageFormat,
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'image_id': imageId,
      'image_format': imageFormat,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
    if (description != null && description.isNotEmpty) {
      body['description'] = description;
    }
    final response = await _api.post(
      '/api/create/quiz',
      token: token,
      body: body,
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

  /// Unggah gambar langsung ke Cloudinary (§4.3), kembalikan identitas aset
  /// (`public_id` + `format` + `secure_url`).
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
    request.fields['type'] = signature.type;
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
    final publicId = data['public_id'];
    if (publicId is! String || publicId.isEmpty) {
      throw const ApiException('Respons Cloudinary tidak valid');
    }
    final format = data['format'];
    if (format is! String || format.isEmpty) {
      throw const ApiException('Respons Cloudinary tidak valid');
    }
    return QuizImageAsset(publicId: publicId, format: format, path: secureUrl);
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
