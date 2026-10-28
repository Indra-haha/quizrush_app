import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:quizrush/models/wallet.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/api/wallet_service.dart';

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
  group('Wallet models', () {
    test('WalletHistoryItem parse and properties', () {
      final claimItem = WalletHistoryItem.fromJson({
        '_id': '0x88d9c24e83f:12',
        'user_id': 'user_123',
        'points_claimed': 1000,
        'rupiah_value': 10000,
        'status': 'SUCCESS',
        'created_at': '2026-10-25T11:34:00Z',
      });

      expect(claimItem.id, '0x88d9c24e83f:12');
      expect(claimItem.userId, 'user_123');
      expect(claimItem.pointsClaimed, 1000);
      expect(claimItem.rupiahValue, 10000.0);
      expect(claimItem.status, 'SUCCESS');
      expect(claimItem.isWithdrawal, isFalse);
      expect(claimItem.isClaim, isTrue);

      final withdrawItem = WalletHistoryItem.fromJson({
        '_id': '0x12ab34cd56e:3',
        'user_id': 'user_123',
        'points_claimed': 0,
        'rupiah_value': -5000,
        'status': 'SUCCESS',
        'created_at': '2026-10-24T09:10:00Z',
      });

      expect(withdrawItem.pointsClaimed, 0);
      expect(withdrawItem.rupiahValue, -5000.0);
      expect(withdrawItem.isWithdrawal, isTrue);
      expect(withdrawItem.isClaim, isFalse);
    });

    test('WalletResponse parse', () {
      final res = WalletResponse.fromJson({
        'status': 'SUCCESS',
        'current_balance': 25000,
        'data': [
          {
            '_id': 'tx_1',
            'user_id': 'u1',
            'points_claimed': 500,
            'rupiah_value': 5000,
            'status': 'SUCCESS',
            'created_at': '2026-10-25T10:00:00Z',
          },
        ],
      });

      expect(res.status, 'SUCCESS');
      expect(res.currentBalance, 25000);
      expect(res.data.length, 1);
      expect(res.data.first.id, 'tx_1');
    });

    test('WalletClaimResult parse', () {
      final res = WalletClaimResult.fromJson({
        'status': 'SUCCESS',
        'message': 'Klaim berhasil dan tercatat permanen di blockchain!',
        'tx_hash': '0x88d9c24e83f...3f1a',
        'remaining_points': 500,
      });

      expect(res.status, 'SUCCESS');
      expect(res.message, contains('Klaim berhasil'));
      expect(res.txHash, '0x88d9c24e83f...3f1a');
      expect(res.remainingPoints, 500);
    });
  });

  group('WalletService', () {
    test('claim points sukses mengirim payload dan mengembalikan result', () async {
      late Map<String, dynamic> sentBody;
      late String? sentAuth;

      final service = WalletService.withApi(
        _api((request) async {
          expect(request.url.path, '/api/wallet/claim');
          sentAuth = request.headers['Authorization'];
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(
            jsonEncode({
              'status': 'SUCCESS',
              'message': 'Klaim berhasil!',
              'tx_hash': '0xabc123',
              'remaining_points': 300,
            }),
            200,
          );
        }),
      );

      final result = await service.claim(
        token: 'test_token',
        userId: 'user_123',
        pointsToClaim: 1000,
        rupiahValue: 10000.0,
      );

      expect(sentAuth, 'Bearer test_token');
      expect(sentBody['user_id'], 'user_123');
      expect(sentBody['points_to_claim'], 1000);
      expect(sentBody['rupiah_value'], 10000.0);
      expect(result.status, 'SUCCESS');
      expect(result.txHash, '0xabc123');
      expect(result.remainingPoints, 300);
    });

    test('claim tarik saldo (points_to_claim: 0, rupiah_value < 0)', () async {
      late Map<String, dynamic> sentBody;

      final service = WalletService.withApi(
        _api((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _json(
            jsonEncode({
              'status': 'SUCCESS',
              'message': 'Penarikan berhasil',
              'tx_hash': '0xdef456',
            }),
            200,
          );
        }),
      );

      final result = await service.claim(
        token: 'test_token',
        pointsToClaim: 0,
        rupiahValue: -5000.0,
      );

      expect(sentBody['points_to_claim'], 0);
      expect(sentBody['rupiah_value'], -5000.0);
      expect(result.status, 'SUCCESS');
    });

    test('claim gagal melempar ApiException dengan pesan error dari server', () async {
      final service = WalletService.withApi(
        _api((request) async {
          return _json(
            jsonEncode({'error': 'Saldo rupiah tidak mencukupi'}),
            400,
          );
        }),
      );

      expect(
        () => service.claim(
          token: 'token',
          pointsToClaim: 0,
          rupiahValue: -100000.0,
        ),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Saldo rupiah tidak mencukupi',
          ),
        ),
      );
    });


  });
}

