import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizrush/models/user.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/api/quiz_service.dart';
import 'package:quizrush/services/api/user_service.dart';
import 'package:quizrush/services/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

ApiClient _api(Future<http.Response> Function(http.Request) handler) {
  return ApiClient(client: MockClient(handler), baseUrl: 'https://test.local');
}

http.Response _json(String body, int status) {
  return http.Response(
    body,
    status,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('User Model with url_img', () {
    test('toJson and fromJson preserves url_img', () {
      const user = User(
        username: 'user123',
        nama: 'User Test',
        sekolah: 'SI-B',
        tanggalLahir: '2000-01-01',
        urlImg: 'https://res.cloudinary.com/test/image/upload/v123/avatar.jpg',
      );

      final json = user.toJson();
      expect(json['url_img'], 'https://res.cloudinary.com/test/image/upload/v123/avatar.jpg');

      final parsed = User.fromJson(json);
      expect(parsed.username, 'user123');
      expect(parsed.nama, 'User Test');
      expect(parsed.sekolah, 'SI-B');
      expect(parsed.tanggalLahir, '2000-01-01');
      expect(parsed.urlImg, 'https://res.cloudinary.com/test/image/upload/v123/avatar.jpg');
    });

    test('copyWith updates url_img', () {
      const user = User(
        username: 'user123',
        nama: 'User Test',
        sekolah: 'SI-B',
        tanggalLahir: '2000-01-01',
      );
      expect(user.urlImg, isNull);

      final updated = user.copyWith(urlImg: 'https://avatar.url/1.png');
      expect(updated.urlImg, 'https://avatar.url/1.png');
      expect(updated.username, 'user123');
    });
  });

  group('SessionService saveUser', () {
    test('saveUser and getUser updates local storage', () async {
      final session = SessionService.instance;
      await session.saveSession('token-123', {
        'username': 'andi',
        'nama': 'Andi',
      });

      var user = await session.getUser();
      expect(user?['username'], 'andi');
      expect(user?['url_img'], isNull);

      await session.saveUser({
        'username': 'andi',
        'nama': 'Andi',
        'url_img': 'https://avatar.url/andi.png',
      });

      user = await session.getUser();
      expect(user?['username'], 'andi');
      expect(user?['url_img'], 'https://avatar.url/andi.png');
    });
  });

  group('UserService PATCH /api/user', () {
    test('updateProfile sends PATCH request with url_img', () async {
      http.Request? capturedRequest;

      final api = _api((req) async {
        capturedRequest = req;
        return _json(
          jsonEncode({
            'success': true,
            'message': 'Profil berhasil diperbarui',
            'user': {
              'username': 'user123',
              'nama': 'User Test',
              'sekolah': 'SI-B',
              'url_img': 'https://cloudinary.com/new_avatar.jpg',
            },
          }),
          200,
        );
      });

      final service = UserService.withApi(api);
      final result = await service.updateProfile(
        token: 'token-abc',
        urlImg: 'https://cloudinary.com/new_avatar.jpg',
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'PATCH');
      expect(capturedRequest!.url.path, '/api/user');
      expect(capturedRequest!.headers['authorization'], 'Bearer token-abc');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['url_img'], 'https://cloudinary.com/new_avatar.jpg');

      expect(result['url_img'], 'https://cloudinary.com/new_avatar.jpg');
      expect(result['username'], 'user123');
    });

    test('updateProfile throws ApiException on failure', () async {
      final api = _api((req) async {
        return _json(jsonEncode({'message': 'Sesi telah berakhir'}), 401);
      });

      final service = UserService.withApi(api);
      expect(
        () => service.updateProfile(token: 'expired', urlImg: 'https://img'),
        throwsA(isA<ApiException>().having((e) => e.message, 'message', 'Sesi telah berakhir')),
      );
    });

    test('updateProfilePhoto completes full signature -> upload -> patch flow', () async {
      http.Request? capturedPatchRequest;

      final mockApi = _api((req) async {
        if (req.method == 'PATCH' && req.url.path == '/api/user') {
          capturedPatchRequest = req;
          return _json(
            jsonEncode({
              'success': true,
              'user': {
                'username': 'user123',
                'url_img': 'https://res.cloudinary.com/mock/image/upload/avatar.jpg',
              },
            }),
            200,
          );
        }
        return _json('{}', 404);
      });

      // Mock QuizService with fake upload result
      final mockQuizApi = _api((req) async {
        if (req.method == 'POST' && req.url.path == '/api/create/signature') {
          return _json(
            jsonEncode({
              'signature': 'fake-sig',
              'timestamp': 1234567890,
              'apiKey': 'fake-key',
              'cloudName': 'mock',
              'type': 'authenticated',
            }),
            200,
          );
        }
        return _json(
          jsonEncode({
            'secure_url': 'https://res.cloudinary.com/mock/image/upload/avatar.jpg',
            'public_id': 'avatar',
            'format': 'jpg',
          }),
          200,
        );
      });

      final quizService = QuizService.withApi(mockQuizApi);
      final userService = UserService.withApi(mockApi);

      final result = await userService.updateProfilePhoto(
        token: 'test-token',
        imageBytes: [1, 2, 3],
        imageFilename: 'test.jpg',
        quizService: quizService,
      );

      expect(capturedPatchRequest, isNotNull);
      expect(capturedPatchRequest!.method, 'PATCH');
      expect(capturedPatchRequest!.url.path, '/api/user');
      final patchBody = jsonDecode(capturedPatchRequest!.body) as Map<String, dynamic>;
      expect(patchBody['url_img'], 'https://res.cloudinary.com/mock/image/upload/avatar.jpg');
      expect(result['url_img'], 'https://res.cloudinary.com/mock/image/upload/avatar.jpg');
    });
  });
}



