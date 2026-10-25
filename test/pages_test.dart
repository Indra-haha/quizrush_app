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
    testWidgets(
      'tab poin menampilkan ringkasan dan riwayat, saldo tetap jalan',
      (WidgetTester tester) async {
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

        expect(find.text('Poin (Pts)'), findsOneWidget);
        expect(find.text('Saldo'), findsOneWidget);
        expect(find.text('TOTAL POIN QUIZRUSH'), findsOneWidget);
        expect(find.text('28.450'), findsOneWidget);
        expect(find.text('Setara : Rp 284.500'), findsOneWidget);
        expect(find.text('Tukarkan Menjadi Mata Uang!'), findsOneWidget);
        expect(find.text('Riwayat Poin Kuis'), findsOneWidget);
        expect(find.text('Hadiah kuis'), findsWidgets);
        expect(find.text('+100 Pts'), findsOneWidget);

        await tester.ensureVisible(find.text('Konversi sekarang!'));
        await tester.tap(find.text('Konversi sekarang!'));
        await tester.pumpAndSettle();

        expect(find.text('Saldo Koin'), findsOneWidget);
        expect(find.text('28.450 KOIN'), findsOneWidget);
        expect(find.text('Konversi Koin'), findsOneWidget);
        expect(find.text('Riwayat Transaksi'), findsOneWidget);

        await tester.tap(find.text('Poin (Pts)'));
        await tester.pumpAndSettle();

        expect(find.text('TOTAL POIN QUIZRUSH'), findsOneWidget);
      },
    );
  });
}
