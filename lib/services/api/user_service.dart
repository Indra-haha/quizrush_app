import 'api_client.dart';
import 'quiz_service.dart';
import '../../helpers/json.dart';

/// Service untuk mengelola data akun user, termasuk endpoint `PATCH /api/user`
/// dan pengunggahan foto profil ke Cloudinary via signature `/api/create/signature`.
class UserService {
  UserService._(this._api);

  /// Instance untuk pengujian dengan [ApiClient] yang di-inject.
  UserService.withApi(this._api);

  static final UserService instance = UserService._(ApiClient.instance);

  final ApiClient _api;

  /// Memperbarui data pengguna via `PATCH /api/user`.
  ///
  /// Menerima [urlImg] (URL foto dari Cloudinary), [nama], [sekolah],
  /// dan [tanggalLahir] secara parsial.
  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? urlImg,
    String? nama,
    String? sekolah,
    String? tanggalLahir,
    Map<String, dynamic>? additionalFields,
  }) async {
    final body = <String, dynamic>{};
    if (urlImg != null) body['url_img'] = urlImg;
    if (nama != null) body['nama'] = nama;
    if (sekolah != null) body['sekolah'] = sekolah;
    if (tanggalLahir != null) body['tanggal_lahir'] = tanggalLahir;
    if (additionalFields != null) body.addAll(additionalFields);

    final response = await _api.patch(
      '/api/user',
      token: token,
      body: body,
    );

    final data = ApiClient.decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        ApiClient.message(data),
        statusCode: response.statusCode,
      );
    }

    if (data is Map<String, dynamic>) {
      if (data['user'] is Map<String, dynamic>) {
        return jsonMap(data['user']);
      }
      return data;
    }
    return <String, dynamic>{};
  }

  /// Alur lengkap unggah foto profil:
  /// 1. Meminta signature Cloudinary ke server lewat `POST /api/create/signature`.
  /// 2. Mengunggah binary gambar langsung ke Cloudinary `POST /image/upload`.
  /// 3. Mengirimkan URL gambar hasil upload (`secure_url`) ke `PATCH /api/user`
  ///    pada field `url_img`.
  Future<Map<String, dynamic>> updateProfilePhoto({
    required String token,
    required List<int> imageBytes,
    required String imageFilename,
    void Function(QuizImageUploadStage stage)? onStage,
    QuizService? quizService,
  }) async {
    final service = quizService ?? QuizService.instance;
    // Unggah gambar ke Cloudinary via alur signature /api/create/signature
    final asset = await service.uploadQuizImage(
      token: token,
      imageBytes: imageBytes,
      imageFilename: imageFilename,
      onStage: onStage,
    );

    // Kirim URL hasil Cloudinary (secure_url) ke PATCH /api/user
    return updateProfile(
      token: token,
      urlImg: asset.path,
    );
  }
}
