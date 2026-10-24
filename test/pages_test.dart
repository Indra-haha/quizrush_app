import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/pages/Reward/reward_page.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/api/points_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'token',
    });
  });

  group('RewardPage', () {
    testWidgets('filter bisa digeser dan saldo tetap fungsional', (
      WidgetTester tester,
    ) async {
      final service = PointsService.withApi(
        ApiClient(
          baseUrl: 'https://test.local',
          client: MockClient((request) async {
            if (request.url.path == '/api/me/points') {
              return http.Response(jsonEncode({'points': 28450}), 200);
            }
            if (request.url.path == '/api/me/coins') {
              return http.Response(
                jsonEncode({
                  'coins': [
                    {
                      'id': '1',
                      'amount': 100,
                      'reason': 'quiz_reward',
                      'created_at': DateTime.now().toIso8601String(),
                      'room_kode': 'ABC123',
                    },
                  ],
                }),
                200,
              );
            }
            return http.Response('{}', 404);
          }),
        ),
      );

      await tester.pumpWidget(_wrap(RewardPage(service: service)));
      await tester.pumpAndSettle();

      expect(find.text('Reward'), findsWidgets);
      expect(find.text('Saldo'), findsOneWidget);
      expect(find.text('Belum ada konten reward.'), findsOneWidget);

      await tester.tap(find.text('Saldo'));
      await tester.pumpAndSettle();

      expect(find.text('Saldo Koin'), findsOneWidget);
      expect(find.text('28.450 KOIN'), findsOneWidget);
      expect(find.text('Konversi Koin'), findsOneWidget);
      expect(find.text('Riwayat Transaksi'), findsOneWidget);
      expect(find.text('Hadiah kuis'), findsWidgets);

      await tester.tap(find.text('Reward'));
      await tester.pumpAndSettle();

      expect(find.text('Belum ada konten reward.'), findsOneWidget);
    });
  });
}
