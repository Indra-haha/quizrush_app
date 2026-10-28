import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizrush/pages/Reward/reward_page.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/api/points_service.dart';
import 'package:quizrush/services/api/wallet_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'auth_token': 'token',
      'auth_user': jsonEncode({'username': 'user_test'}),
    });
  });

  group('RewardPage', () {
    testWidgets(
      'tab poin dan tab saldo menampilkan saldo dan riwayat',
      (WidgetTester tester) async {
        final mockApi = ApiClient(
          baseUrl: 'https://test.local',
          client: MockClient((request) async {
            if (request.url.path == '/api/me/points') {
              return http.Response(
                jsonEncode({
                  'message': 'Saldo poin',
                  'points': 28450,
                  'history': [
                    {
                      'id': '1',
                      'amount': '+100',
                      'reason': 'quiz_reward',
                      'created_at': DateTime.now().toIso8601String(),
                      'room_kode': 'ABC123',
                    },
                  ],
                }),
                200,
              );
            }
            if (request.url.path == '/api/me/wallet' ||
                request.url.path == '/api/wallet/user_test') {
              return http.Response(
                jsonEncode({
                  'status': 'SUCCESS',
                  'message': 'Riwayat wallet on-chain',
                  'current_balance': 50000,
                  'data': [
                    {
                      '_id': '0xabc123:1',
                      'user_id': 'user_test',
                      'points_claimed': 1000,
                      'rupiah_value': 10000,
                      'status': 'SUCCESS',
                      'created_at': DateTime.now().toIso8601String(),
                    },
                  ],
                }),
                200,
              );
            }
            return http.Response('{}', 404);
          }),
        );

        final pointsService = PointsService.withApi(mockApi);
        final walletService = WalletService.withApi(mockApi);

        await tester.pumpWidget(
          _wrap(
            RewardPage(
              service: pointsService,
              walletService: walletService,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Poin (Pts)'), findsOneWidget);
        expect(find.text('Saldo'), findsOneWidget);
        expect(find.text('TOTAL POIN QUIZRUSH'), findsOneWidget);
        expect(find.text('28.450'), findsOneWidget);
        expect(find.text('Setara: Rp 284.500'), findsOneWidget);
        expect(find.text('Tukarkan Menjadi Mata Uang!'), findsOneWidget);
        expect(find.text('Riwayat Poin Kuis'), findsOneWidget);
        expect(find.text('Hadiah kuis'), findsWidgets);
        expect(find.text('+100 Pts'), findsOneWidget);

        await tester.ensureVisible(find.text('Konversi sekarang!'));
        await tester.tap(find.text('Konversi sekarang!'));
        await tester.pumpAndSettle();

        expect(find.text('TOTAL RUPIAH'), findsOneWidget);
        expect(find.text('Rp 50.000'), findsOneWidget);
        expect(find.text('Konversi Poin ke Rupiah'), findsOneWidget);

        await tester.drag(find.byType(ListView).last, const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('Riwayat Transaksi Saldo'), findsOneWidget);
        expect(find.text('Klaim Poin (1.000 Pts)'), findsOneWidget);
        expect(find.text('+Rp 10.000'), findsOneWidget);

        await tester.tap(find.text('Poin (Pts)'));
        await tester.pumpAndSettle();

        expect(find.text('TOTAL POIN QUIZRUSH'), findsOneWidget);
      },
    );
  });
}
