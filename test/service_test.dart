import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizrush/helpers/password_hasher.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/services/api/ai_service.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/api/auth_service.dart';
import 'package:quizrush/services/api/quiz_service.dart';
import 'package:quizrush/services/api/result_service.dart';
import 'package:quizrush/services/api/room_service.dart';

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
  group('ApiClient', () {
    test('uri menggabungkan baseUrl dan path', () {
      final api = _api((_) async => _json('{}', 200));
      expect(
        api.uri('/api/quizzes').toString(),
        'https://test.local/api/quizzes',
      );
    });

    test('headers mengisi Authorization dan User-Agent', () {
      final api = _api((_) async => _json('{}', 200));
      final headers = api.headers(token: 'abc', body: true);
      expect(headers['Authorization'], 'Bearer abc');
      expect(headers['Content-Type'], 'application/json');
      expect(headers['User-Agent'], isNotEmpty);
    });

    test('decode mengembalikan map kosong untuk body tidak valid', () {
      expect(ApiClient.decode(http.Response('bukan json', 200)), isEmpty);
      expect(ApiClient.decode(http.Response('{"a":1}', 200)), {'a': 1});
    });

    test('message memakai pesan server atau default', () {
      expect(ApiClient.message({'message': 'gagal'}), 'gagal');
      expect(ApiClient.message({'x': 1}), 'Terjadi kesalahan');
      expect(ApiClient.message(null), 'Terjadi kesalahan');
    });

    test('message memakai status code saat body bukan JSON', () {
      expect(
        ApiClient.message('bukan json', statusCode: 504),
        'Terjadi kesalahan pada server (HTTP 504)',
      );
    });

    test('get mengirim bearer token', () async {
      String? auth;
      final api = _api((request) async {
        auth = request.headers['Authorization'];
        return _json('{}', 200);
      });
      await api.get('/api/session', token: 'xyz');
      expect(auth, 'Bearer xyz');
    });
  });

  group('AuthService', () {
    test('login sukses mengembalikan token dan user', () async {
      String? sentDevice;
      String? sentPassword;
      final service = AuthService.withApi(
        _api((request) async {
          sentDevice = request.body.contains('device_id') ? 'ada' : null;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sentPassword = body['password'] as String?;
          return _json(
            '{"token":"jwt","user":{"username":"budi","nama":"Budi"}}',
            200,
          );
        }),
      );

      final result = await service.login(username: 'budi', password: 'rahasia');
      expect(result.token, 'jwt');
      expect(result.user['username'], 'budi');
      expect(sentDevice, 'ada');
      expect(sentPassword, hashPassword('rahasia'));
      expect(sentPassword, isNot('rahasia'));
    });

    test('loginWithHash mengirim hash apa adanya', () async {
      String? sentPassword;
      final service = AuthService.withApi(
        _api((request) async {
          sentPassword =
              (jsonDecode(request.body) as Map<String, dynamic>)['password']
                  as String?;
          return _json('{"token":"jwt","user":{"username":"budi"}}', 200);
        }),
      );

      final result = await service.loginWithHash(
        username: 'budi',
        passwordHash: 'hash-tersimpan',
      );
      expect(sentPassword, 'hash-tersimpan');
      expect(result.token, 'jwt');
    });

    test('login gagal melempar ApiException dengan pesan server', () async {
      final service = AuthService.withApi(
        _api(
          (_) async => _json('{"message":"Username atau password salah"}', 401),
        ),
      );

      expect(
        () => service.login(username: 'budi', password: 'x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having(
                (e) => e.message,
                'message',
                'Username atau password salah',
              ),
        ),
      );
    });

    test('register sukses mengembalikan User', () async {
      String? sentPassword;
      final service = AuthService.withApi(
        _api((request) async {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          sentPassword = body['password'] as String?;
          return _json(
            '{"user":{"username":"budi","nama":"Budi","kelas":"6A","tanggal_lahir":"2005-03-05"}}',
            201,
          );
        }),
      );

      final user = await service.register(
        nama: 'Budi',
        username: 'budi',
        kelas: '6A',
        tanggalLahir: '2005-03-05',
        password: 'rahasia',
      );
      expect(user.username, 'budi');
      expect(user.kelas, '6A');
      expect(sentPassword, hashPassword('rahasia'));
    });

    test('logout gagal melempar ApiException', () async {
      final service = AuthService.withApi(
        _api((_) async => _json('{"message":"unauthorized"}', 401)),
      );
      expect(() => service.logout('token'), throwsA(isA<ApiException>()));
    });

    test('checkSession mengembalikan map user', () async {
      final service = AuthService.withApi(
        _api((_) async => _json('{"user":{"username":"budi"}}', 200)),
      );
      final user = await service.checkSession('token');
      expect(user['username'], 'budi');
    });
  });

  group('QuizService', () {
    test('getQuizzes mem-parse grup AllQuizzes', () async {
      final service = QuizService.withApi(
        _api(
          (_) async => _json(
            '{"open":[{"id":"q1","title":"Kuis"}],"in-Game":[],"ended":[]}',
            200,
          ),
        ),
      );

      final data = await service.getQuizzes('token');
      expect(data.open.single.title, 'Kuis');
      expect(data.ended, isEmpty);
    });

    test('getMyQuizzes mem-parse lima grup', () async {
      final service = QuizService.withApi(
        _api(
          (_) async => _json(
            '{"waiting":[{"id":"q1"}],"open":[],"in-Game":[],"ended":[],"quarantine":[]}',
            200,
          ),
        ),
      );

      final data = await service.getMyQuizzes('token');
      expect(data.waiting.single.id, 'q1');
      expect(data.isEmpty, isFalse);
    });

    test('getQuizzes non-200 melempar ApiException', () async {
      final service = QuizService.withApi(
        _api((_) async => _json('{"message":"unauthorized"}', 401)),
      );
      expect(
        () => service.getQuizzes('token'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });

    test('uploadQuizImage: signature lalu upload lalu secure_url', () async {
      final calls = <String>[];
      final stages = <QuizImageUploadStage>[];

      final service = QuizService.withApi(
        _api((request) async {
          calls.add('${request.url.host}${request.url.path}');
          if (request.url.path == '/api/create/signature') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            expect(body['folder'], 'galery-quiz/quiz-image');
            expect(request.headers['authorization'], 'Bearer token');
            return _json(
              '{"success":true,"signature":"abc123","timestamp":1792154580,'
              '"apiKey":"123456789012345","cloudName":"dlxxyz123",'
              '"type":"authenticated"}',
              200,
            );
          }
          expect(request.url.path, '/v1_1/dlxxyz123/image/upload');
          expect(
            request.headers['content-type'],
            contains('multipart/form-data'),
          );
          final body = request.body;
          expect(body, contains('name="api_key"'));
          expect(body, contains('123456789012345'));
          expect(body, contains('name="timestamp"'));
          expect(body, contains('1792154580'));
          expect(body, contains('name="signature"'));
          expect(body, contains('abc123'));
          expect(body, contains('name="folder"'));
          expect(body, contains('galery-quiz/quiz-image'));
          expect(body, contains('name="type"'));
          expect(body, contains('authenticated'));
          expect(body, contains('filename="cover.png"'));
          return _json(
            '{"public_id":"galery-quiz/quiz-image/cover","format":"png",'
            '"secure_url":"https://res.cloudinary.com/dlxxyz123/image/'
            'authenticated/v1792154580/galery-quiz/quiz-image/cover.png"}',
            200,
          );
        }),
      );

      final asset = await service.uploadQuizImage(
        token: 'token',
        imageBytes: 'PNGDATA'.codeUnits,
        imageFilename: 'cover.png',
        onStage: stages.add,
      );

      expect(calls, [
        'test.local/api/create/signature',
        'api.cloudinary.com/v1_1/dlxxyz123/image/upload',
      ]);
      expect(stages, [
        QuizImageUploadStage.requestingSignature,
        QuizImageUploadStage.uploading,
      ]);
      expect(asset.path, isNotEmpty);
      expect(
        asset.path,
        'https://res.cloudinary.com/dlxxyz123/image/authenticated/'
        'v1792154580/galery-quiz/quiz-image/cover.png',
      );
      expect(asset.publicId, 'galery-quiz/quiz-image/cover');
      expect(asset.format, 'png');
    });

    test(
      'uploadQuizImage menerima signature snake_case & timestamp string',
      () async {
        final service = QuizService.withApi(
          _api((request) async {
            if (request.url.path == '/api/create/signature') {
              return _json(
                '{"signature":"abc","timestamp":"1792154580",'
                '"api_key":"key","cloud_name":"cloud"}',
                200,
              );
            }
            expect(request.url.path, '/v1_1/cloud/image/upload');
            final body = request.body;
            expect(body, contains('name="type"'));
            expect(body, contains('authenticated'));
            return _json(
              '{"public_id":"x","format":"png",'
              '"secure_url":"https://res.cloudinary.com/cloud/image/upload/x.png"}',
              200,
            );
          }),
        );

        final asset = await service.uploadQuizImage(
          token: 'token',
          imageBytes: 'PNGDATA'.codeUnits,
          imageFilename: 'x.png',
        );

        expect(
          asset.path,
          'https://res.cloudinary.com/cloud/image/upload/x.png',
        );
        expect(asset.publicId, 'x');
        expect(asset.format, 'png');
      },
    );

    test(
      'uploadQuizImage memakai type dari respons signature',
      () async {
        final service = QuizService.withApi(
          _api((request) async {
            if (request.url.path == '/api/create/signature') {
              return _json(
                '{"signature":"abc","timestamp":1,"apiKey":"k",'
                '"cloudName":"c","type":"upload"}',
                200,
              );
            }
            final body = request.body;
            expect(body, contains('name="type"'));
            expect(body, contains('upload'));
            expect(body, isNot(contains('authenticated')));
            return _json(
              '{"public_id":"x","format":"png",'
              '"secure_url":"https://res.cloudinary.com/cloud/image/upload/x.png"}',
              200,
            );
          }),
        );

        await service.uploadQuizImage(
          token: 'token',
          imageBytes: 'PNGDATA'.codeUnits,
          imageFilename: 'x.png',
        );
      },
    );

    test(
      'uploadQuizImage respons Cloudinary tanpa public_id melempar ApiException',
      () async {
        final service = QuizService.withApi(
          _api((request) async {
            if (request.url.path == '/api/create/signature') {
              return _json(
                '{"signature":"abc","timestamp":1,"apiKey":"k","cloudName":"c"}',
                200,
              );
            }
            return _json(
              '{"secure_url":"https://res.cloudinary.com/cloud/image/upload/x.png"}',
              200,
            );
          }),
        );

        await expectLater(
          () => service.uploadQuizImage(
            token: 'token',
            imageBytes: 'PNGDATA'.codeUnits,
            imageFilename: 'x.png',
          ),
          throwsA(
            isA<ApiException>().having(
              (e) => e.message,
              'message',
              'Respons Cloudinary tidak valid',
            ),
          ),
        );
      },
    );

    test(
      'uploadQuizImage signature gagal melempar ApiException sebelum upload',
      () async {
        var uploaded = false;
        final service = QuizService.withApi(
          _api((request) async {
            if (request.url.host == 'api.cloudinary.com') {
              uploaded = true;
            }
            return _json(
              '{"message":"konfigurasi Cloudinary belum lengkap"}',
              500,
            );
          }),
        );
        await expectLater(
          () => service.uploadQuizImage(
            token: 'token',
            imageBytes: const [1, 2, 3],
            imageFilename: 'c.png',
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', 500)
                .having(
                  (e) => e.message,
                  'message',
                  'konfigurasi Cloudinary belum lengkap',
                ),
          ),
        );
        expect(uploaded, isFalse);
      },
    );

    test(
      'uploadQuizImage gagal upload Cloudinary melempar ApiException',
      () async {
        final service = QuizService.withApi(
          _api((request) async {
            if (request.url.path == '/api/create/signature') {
              return _json(
                '{"signature":"abc","timestamp":1,"apiKey":"k","cloudName":"c"}',
                200,
              );
            }
            return _json(
              '{"error":{"message":"Signature match invalid"}}',
              401,
            );
          }),
        );
        expect(
          () => service.uploadQuizImage(
            token: 'token',
            imageBytes: const [1, 2, 3],
            imageFilename: 'c.png',
          ),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'status', 401)
                .having((e) => e.message, 'message', 'Signature match invalid'),
          ),
        );
      },
    );

    test('createQuiz mengirim JSON berisi image_id dan image_format', () async {
      String? contentType;
      String? body;

      final service = QuizService.withApi(
        _api((request) async {
          contentType = request.headers['content-type'];
          body = request.body;
          return _json('{"quiz":{"id":"q9","title":"Kuis Baru"}}', 201);
        }),
      );

      final quiz = await service.createQuiz(
        token: 'token',
        title: 'Kuis Baru',
        description: 'Deskripsi',
        questions: const [
          QuizQuestionInput(
            question: 'q',
            options: ['a', 'b', 'c', 'd'],
            correctIdx: 0,
            duration: 2,
            skor: 10,
          ),
        ],
        imageId: 'galery-quiz/quiz-image/cover',
        imageFormat: 'png',
      );

      expect(contentType, 'application/json');
      expect(body, contains('"title":"Kuis Baru"'));
      expect(body, contains('"image_id":"galery-quiz/quiz-image/cover"'));
      expect(body, contains('"image_format":"png"'));
      expect(quiz.id, 'q9');
    });

    test('createQuiz non-201 melempar ApiException', () async {
      final service = QuizService.withApi(
        _api((_) async => _json('{"message":"validasi gagal"}', 422)),
      );
      expect(
        () => service.createQuiz(
          token: 'token',
          title: 'Kuis',
          questions: const [],
          imageId: 'galery-quiz/quiz-image/cover',
          imageFormat: 'png',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'status', 422)
              .having((e) => e.message, 'message', 'validasi gagal'),
        ),
      );
    });
  });

  group('RoomService', () {
    test('verifyPin mem-parse token dan room', () async {
      final service = RoomService.withApi(
        _api(
          (_) async => _json(
            '{"token":"room-jwt","room":{"id":"r1","kode":"123456","status":"waiting"}}',
            200,
          ),
        ),
      );

      final result = await service.verifyPin(token: 'token', pin: '123456');
      expect(result.token, 'room-jwt');
      expect(result.room.kode, '123456');
    });

    test('verifyPin gagal melempar ApiException', () async {
      final service = RoomService.withApi(
        _api((_) async => _json('{"message":"PIN tidak valid"}', 400)),
      );
      expect(
        () => service.verifyPin(token: 'token', pin: '000000'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'PIN tidak valid',
          ),
        ),
      );
    });

    test('createRoom sukses mem-parse room', () async {
      final service = RoomService.withApi(
        _api(
          (_) async => _json(
            '{"room":{"id":"r1","kode":"123456","status":"waiting"}}',
            201,
          ),
        ),
      );
      final room = await service.createRoom(token: 'token', quizId: 'q1');
      expect(room.id, 'r1');
    });

    test('createRoom mengirim type saat private', () async {
      String? body;
      final service = RoomService.withApi(
        _api((request) async {
          body = request.body;
          return _json(
            '{"room":{"id":"r1","kode":"123456","status":"waiting"}}',
            201,
          );
        }),
      );
      await service.createRoom(
        token: 'token',
        quizId: 'q1',
        judul: 'Room Private',
        type: 'private',
      );
      final payload = jsonDecode(body!) as Map<String, dynamic>;
      expect(payload['type'], 'private');
      expect(payload['judul'], 'Room Private');
      expect(payload.containsKey('isi'), isFalse);
      expect(payload.containsKey('status'), isFalse);
    });

    test('createRoom tanpa type tidak mengirim field type', () async {
      String? body;
      final service = RoomService.withApi(
        _api((request) async {
          body = request.body;
          return _json(
            '{"room":{"id":"r1","kode":"123456","status":"waiting"}}',
            201,
          );
        }),
      );
      await service.createRoom(token: 'token', quizId: 'q1');
      final payload = jsonDecode(body!) as Map<String, dynamic>;
      expect(payload.containsKey('type'), isFalse);
    });

    test('updateRoomStatus memakai PUT dan mem-parse room', () async {
      String? method;
      final service = RoomService.withApi(
        _api((request) async {
          method = request.method;
          return _json(
            '{"room":{"id":"r1","kode":"123456","status":"open"}}',
            200,
          );
        }),
      );
      final room = await service.updateRoomStatus(
        token: 'token',
        roomId: 'r1',
        status: 'open',
      );
      expect(method, 'PUT');
      expect(room.status, 'open');
    });
  });

  group('AiService', () {
    test('suggestQuestions mengirim topic dan mem-parse daftar soal', () async {
      String? path;
      String? auth;
      Map<String, dynamic>? body;
      final service = AiService.withApi(
        _api((request) async {
          path = request.url.path;
          auth = request.headers['Authorization'];
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return _json('''
{
  "message": "Saran soal berhasil dibuat",
  "questions": [
    {
      "question": "Apa ibu kota Indonesia?",
      "options": ["Bandung", "Jakarta", "Surabaya", "Medan"],
      "correct_idx": 1,
      "duration": 3,
      "skor": 20
    }
  ]
}''', 200);
        }),
      );

      final result = await service.suggestQuestions(
        token: 'tok',
        topic: 'Geografi Indonesia',
      );
      expect(path, '/api/ai/suggest');
      expect(auth, 'Bearer tok');
      expect(body?['topic'], 'Geografi Indonesia');
      expect(body!.containsKey('count'), isFalse);
      expect(result, hasLength(1));
      expect(result.first.question, 'Apa ibu kota Indonesia?');
      expect(result.first.options, hasLength(4));
      expect(result.first.correctIdx, 1);
      expect(result.first.duration, 3);
      expect(result.first.skor, 20);
    });

    test(
      'suggestQuestions membuang soal tidak valid dan menormalisasi',
      () async {
        final service = AiService.withApi(
          _api(
            (_) async => _json('''
{
  "questions": [
    { "question": "", "options": ["a","b","c","d"], "correct_idx": 0, "duration": 2, "skor": 10 },
    { "question": "Opsi tidak 4", "options": ["a","b"], "correct_idx": 0, "duration": 2, "skor": 10 },
    { "question": "Di luar batas", "options": ["a","b","c","d"], "correct_idx": 9, "duration": 7.5, "skor": 999 }
  ]
}''', 200),
          ),
        );

        final result = await service.suggestQuestions(token: 't', topic: 'x');
        expect(result, hasLength(1));
        expect(result.first.question, 'Di luar batas');
        expect(result.first.correctIdx, 0);
        expect(result.first.duration, 2.0);
        expect(result.first.skor, 10);
      },
    );

    test(
      'suggestQuestions melempar ApiException non-transien dengan pesan server',
      () async {
        final service = AiService.withApi(
          _api(
            (_) async => _json('{"message":"Terjadi kesalahan server"}', 500),
          ),
        );
        expect(
          () => service.suggestQuestions(token: 't', topic: 'x'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 500)
                .having(
                  (e) => e.message,
                  'message',
                  'Terjadi kesalahan server',
                ),
          ),
        );
      },
    );

    test('suggestQuestions mencoba ulang sekali saat provider sibuk', () async {
      var calls = 0;
      final service = AiService.withApi(
        _api((_) async {
          calls++;
          if (calls == 1) {
            return _json('{"message":"Model AI gagal merespons"}', 502);
          }
          return _json('''
{
  "questions": [
    {
      "question": "Apa ibu kota Indonesia?",
      "options": ["Bandung", "Jakarta", "Surabaya", "Medan"],
      "correct_idx": 1,
      "duration": 3,
      "skor": 20
    }
  ]
}''', 200);
        }),
      );

      final result = await service.suggestQuestions(token: 't', topic: 'x');
      expect(calls, 2);
      expect(result, hasLength(1));
    });

    test(
      'suggestQuestions memberi pesan sibuk setelah ulangan transien habis',
      () async {
        var calls = 0;
        final service = AiService.withApi(
          _api((_) async {
            calls++;
            return _json('{"message":"Model AI gagal merespons"}', 503);
          }),
        );
        await expectLater(
          service.suggestQuestions(token: 't', topic: 'x'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.statusCode, 'statusCode', 503)
                .having(
                  (e) => e.message,
                  'message',
                  'Model AI sedang sibuk. Coba lagi sebentar lagi.',
                ),
          ),
        );
        expect(calls, AiService.maxAttempts);
      },
    );

    test(
      'suggestQuestions mengembalikan list kosong saat questions bukan list',
      () async {
        final service = AiService.withApi(
          _api((_) async => _json('{"questions":"bukan-list"}', 200)),
        );
        final result = await service.suggestQuestions(token: 't', topic: 'x');
        expect(result, isEmpty);
      },
    );
  });

  group('ResultService', () {
    test('fetchResults mem-parse entries dan mengirim token', () async {
      late http.Request captured;
      final service = ResultService.withApi(
        _api((request) async {
          captured = request;
          return _json(
            '{"results":[{"id":"r1","room_id":"room1","kode":"482913",'
            '"quiz_id":"q1","entries":[{"nama":"Budi Santoso","skor":87}],'
            '"created_at":"2026-10-05T20:03:00Z"}]}',
            200,
          );
        }),
      );

      final results = await service.fetchResults(token: 'token');

      expect(captured.url.path, '/api/results');
      expect(captured.headers['authorization'], 'Bearer token');
      expect(results, hasLength(1));
      expect(results.single.kode, '482913');
      expect(results.single.entries.single.nama, 'Budi Santoso');
      expect(results.single.entries.single.skor, 87);
    });

    test('fetchResults menyertakan limit dan skip', () async {
      late http.Request captured;
      final service = ResultService.withApi(
        _api((request) async {
          captured = request;
          return _json('{"results":[]}', 200);
        }),
      );

      await service.fetchResults(token: 'token', limit: 10, skip: 20);

      expect(captured.url.queryParameters['limit'], '10');
      expect(captured.url.queryParameters['skip'], '20');
    });

    test('fetchResults non-200 melempar ApiException', () async {
      final service = ResultService.withApi(
        _api((_) async => _json('{"message":"unauthorized"}', 401)),
      );

      expect(
        () => service.fetchResults(token: 'token'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
    });
  });
}
