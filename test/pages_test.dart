import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/pages/ranking_region_page.dart';
import 'package:quizrush/pages/profile_page.dart';
import 'package:quizrush/pages/saldo/saldo_page.dart';
import 'package:quizrush/services/api_client.dart';
import 'package:quizrush/services/points_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

PointsService _saldoService() {
  final client = MockClient((request) async {
    final body = switch (request.url.path) {
      '/api/me/points' => jsonEncode({'message': 'Saldo poin', 'points': 28450}),
      '/api/me/coins' => jsonEncode({
        'message': 'Riwayat koin',
        'coins': [
          {
            'id': '1',
            'amount': 1500,
            'reason': 'quiz_reward',
            'room_kode': '482913',
            'quiz_id': 'q1',
            'created_at': '2026-10-05T20:03:00Z',
            'prev_hash': '',
            'hash': 'abc',
          },
        ],
      }),
      _ => jsonEncode({'message': 'not found'}),
    };
    return http.Response(
      body,
      200,
      headers: {'content-type': 'application/json'},
    );
  });
  return PointsService.withApi(
    ApiClient(client: client, baseUrl: 'https://test.local'),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('RankingRegionPage', () {
    testWidgets('menampilkan kartu lokasi dan daftar peringkat', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pump();

      expect(find.text('Peringkat'), findsOneWidget);
      expect(find.text('Lokasi Sekarang'), findsOneWidget);
      expect(find.text('Kecamatan, Kota, Provinsi'), findsOneWidget);
      expect(find.text('Peringkat Wilayah'), findsOneWidget);
      expect(find.text('Arka Pratama'), findsOneWidget);

      final me = find.text('Kamu (Dimas Arya)');
      await tester.scrollUntilVisible(
        me,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(me, findsOneWidget);
    });
  });

  group('SaldoPage', () {
    testWidgets('menampilkan saldo koin, konversi, dan riwayat', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'token',
      });

      await tester.pumpWidget(_wrap(SaldoPage(service: _saldoService())));
      await tester.pump();
      await tester.pump();

      expect(find.text('Saldo'), findsOneWidget);
      expect(find.text('SALDO KOIN QUIZRUSH'), findsOneWidget);
      expect(find.text('28.450'), findsWidgets);
      expect(find.text('≈ Rp 284.500'), findsOneWidget);
      expect(find.text('Konversi Koin'), findsOneWidget);

      final riwayat = find.text('Riwayat Transaksi');
      await tester.scrollUntilVisible(
        riwayat,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(riwayat, findsOneWidget);

      final hadiah = find.text('Hadiah kuis');
      await tester.scrollUntilVisible(
        hadiah,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(hadiah, findsOneWidget);
    });
  });

  group('ProfilePage', () {
    testWidgets('menampilkan data user dan tombol Logout', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ProfilePage(
            user: {
              'nama': 'Budi Santoso',
              'username': 'budi',
              'kelas': 'XI IPA 1',
              'tanggal_lahir': '17/08/2006',
            },
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('@budi'), findsOneWidget);
      expect(find.text('XI IPA 1'), findsOneWidget);
      expect(find.text('2006-08-17'), findsOneWidget);

      final logoutButton = find.widgetWithText(FilledButton, 'Logout');
      await tester.scrollUntilVisible(
        logoutButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(logoutButton, findsOneWidget);
    });
  });
}
