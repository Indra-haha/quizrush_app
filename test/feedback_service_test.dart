import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizrush/pages/Profiles/feedback_page.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/feedback_page.dart';

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
  group('Feedback Models (§16.1)', () {
    test('FeedbackRequest serialization memangkas spasi', () {
      const req = FeedbackRequest(
        username: '  124240200  ',
        saran: '  Tambahkan mode latihan soal per bab.  ',
        kesan: '  Aplikasinya seru dan mudah dipakai.  ',
      );

      final json = req.toJson();
      expect(json['username'], '124240200');
      expect(json['saran'], 'Tambahkan mode latihan soal per bab.');
      expect(json['kesan'], 'Aplikasinya seru dan mudah dipakai.');
    });

    test('FeedbackItem dan FeedbackResponse parsing response 201', () {
      final json = {
        'message': 'Feedback berhasil dikirim',
        'feedback': {
          'id': '671f2f7a9c3e4b0012a4d5e6',
          'username': '124240200',
          'saran': 'Tambahkan mode latihan soal per bab.',
          'kesan': 'Aplikasinya seru dan mudah dipakai.',
          'created_at': '2026-10-28T10:15:00+07:00',
        },
      };

      final response = FeedbackResponse.fromJson(json);
      expect(response.message, 'Feedback berhasil dikirim');
      expect(response.feedback.id, '671f2f7a9c3e4b0012a4d5e6');
      expect(response.feedback.username, '124240200');
      expect(response.feedback.saran, 'Tambahkan mode latihan soal per bab.');
      expect(response.feedback.kesan, 'Aplikasinya seru dan mudah dipakai.');
      expect(response.feedback.createdAt, '2026-10-28T10:15:00+07:00');

      final serialized = response.toJson();
      expect(serialized['message'], 'Feedback berhasil dikirim');
      expect(serialized['feedback']['id'], '671f2f7a9c3e4b0012a4d5e6');
    });
  });

  group('FeedbackService POST /api/feedback (§16.1)', () {
    test('sukses mengirim feedback dengan response 201 Created', () async {
      late Map<String, dynamic> sentBody;
      late String sentPath;
      late String sentMethod;

      final service = FeedbackService.withApi(
        _api((request) async {
          sentPath = request.url.path;
          sentMethod = request.method;
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(
            jsonEncode({
              'message': 'Feedback berhasil dikirim',
              'feedback': {
                'id': '671f2f7a9c3e4b0012a4d5e6',
                'username': '124240200',
                'saran': 'Tambahkan mode latihan soal per bab.',
                'kesan': 'Aplikasinya seru dan mudah dipakai.',
                'created_at': '2026-10-28T10:15:00+07:00',
              },
            }),
            201,
          );
        }),
      );

      final result = await service.sendFeedback(
        username: '124240200',
        saran: 'Tambahkan mode latihan soal per bab.',
        kesan: 'Aplikasinya seru dan mudah dipakai.',
      );

      expect(sentMethod, 'POST');
      expect(sentPath, '/api/feedback');
      expect(sentBody['username'], '124240200');
      expect(sentBody['saran'], 'Tambahkan mode latihan soal per bab.');
      expect(sentBody['kesan'], 'Aplikasinya seru dan mudah dipakai.');
      expect(result.message, 'Feedback berhasil dikirim');
      expect(result.feedback.id, '671f2f7a9c3e4b0012a4d5e6');
    });

    test('validasi input kosong sebelum memanggil HTTP', () async {
      final service = FeedbackService.withApi(
        _api((request) async => _json('{}', 200)),
      );

      expect(
        () => service.sendFeedback(username: '   ', saran: 'ok', kesan: 'ok'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'username wajib diisi',
          ),
        ),
      );

      expect(
        () => service.sendFeedback(username: 'user', saran: '', kesan: 'ok'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'saran wajib diisi',
          ),
        ),
      );

      expect(
        () => service.sendFeedback(username: 'user', saran: 'ok', kesan: '  '),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'kesan wajib diisi',
          ),
        ),
      );
    });

    test('gagal 400 melempar ApiException dari response server', () async {
      final service = FeedbackService.withApi(
        _api((request) async {
          return _json(jsonEncode({'message': 'saran wajib diisi'}), 400);
        }),
      );

      expect(
        () => service.sendFeedback(
          username: 'user1',
          saran: 'a',
          kesan: 'b',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.message, 'message', 'saran wajib diisi')
              .having((e) => e.statusCode, 'statusCode', 400),
        ),
      );
    });
  });

  group('FeedbackPage Widget UI', () {
    testWidgets('menampilkan header, form field username, kesan, saran, dan tombol kirim', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FeedbackPage(),
        ),
      );
      await tester.pump();

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Kesan'), findsOneWidget);
      expect(find.text('Saran'), findsOneWidget);
      expect(find.text('Kirim Feedback'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });
}
