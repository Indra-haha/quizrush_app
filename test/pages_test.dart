import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/pages/QuizPage/enter_pin_page.dart';
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

  Map<String, Object> locationCache({
    required List<Map<String, Object>> kecamatan,
    String timestamp = '2026-10-20T06:30:00Z',
  }) {
    return {
      'region_location': jsonEncode({
        'metadata': {
          'user_location': {'latitude': -7.79558, 'longitude': 110.36949},
          'resolved_regions': {
            'kecamatan': 'kecamatan-pasteur',
            'kota': 'kota-bandung',
            'provinsi': 'provinsi-jabar',
          },
          'timestamp': timestamp,
        },
        'data': {
          'kecamatan': kecamatan,
          'kota': <Map<String, Object>>[],
          'provinsi': <Map<String, Object>>[],
        },
      }),
    };
  }

  Map<String, Object> entry(int rank, String username, String nama, int poin) {
    return {
      'rank': rank,
      'username': username,
      'nama': nama,
      'poin': poin,
      'jarak_meter': 100.0 * rank,
    };
  }

  group('RankingRegionPage', () {
    testWidgets('menampilkan podium & daftar dari cache /api/location', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'token',
        'auth_user': jsonEncode({'username': 'dimas', 'nama': 'Dimas Arya'}),
        ...locationCache(
          kecamatan: [
            entry(1, 'arka', 'Arka Pratama', 14850),
            entry(2, 'nadia', 'Nadia Putri', 12400),
            entry(3, 'rian', 'Rian Setiawan', 11900),
            entry(4, 'faris', 'Faris Alfarisi', 10850),
            entry(5, 'dimas', 'Dimas Arya', 8950),
          ],
        ),
      });

      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pump();
      await tester.pump();

      expect(find.text('Peringkat'), findsOneWidget);
      expect(find.text('Lokasi Sekarang'), findsOneWidget);
      expect(
        find.text('kecamatan-pasteur, kota-bandung, provinsi-jabar'),
        findsOneWidget,
      );
      expect(find.text('Peringkat Wilayah'), findsOneWidget);
      expect(find.text('Top 5'), findsOneWidget);
      expect(find.text('Arka Pratama'), findsOneWidget);
      expect(find.text('@arka'), findsOneWidget);
      expect(find.text('Juara 1'), findsOneWidget);

      final me = find.text('Kamu (Dimas Arya)');
      await tester.scrollUntilVisible(
        me,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(me, findsOneWidget);
      expect(find.text('@dimas'), findsOneWidget);
    });

    testWidgets('menempelkan baris "Kamu" di luar 10 besar', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'token',
        'auth_user': jsonEncode({'username': 'dimas', 'nama': 'Dimas Arya'}),
        ...locationCache(
          kecamatan: [
            for (var i = 1; i <= 12; i++)
              entry(i, 'user$i', 'User $i', 20000 - i * 100),
            entry(13, 'dimas', 'Dimas Arya', 8950),
          ],
        ),
      });

      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pump();
      await tester.pump();

      expect(find.text('Top 13'), findsOneWidget);

      final me = find.text('Kamu (Dimas Arya)');
      await tester.scrollUntilVisible(
        me,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(me, findsOneWidget);
    });

    testWidgets('menampilkan pesan kosong tanpa data lokasi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pump();

      expect(find.text('Lokasi Sekarang'), findsOneWidget);
      expect(find.text('Kecamatan, Kota, Provinsi'), findsOneWidget);
      expect(find.text('Belum ada data peringkat wilayah.'), findsOneWidget);
      expect(find.text('Peringkat Wilayah'), findsNothing);
    });
  });

  group('EnterPinPage', () {
    testWidgets('menampilkan hero, form PIN, nama panggilan, dan tombol gabung', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const EnterPinPage()));
      await tester.pump();

      expect(find.text('Siap Main?'), findsOneWidget);
      expect(
        find.text('Masukkan PIN permainan untuk bergabung'),
        findsOneWidget,
      );
      expect(find.text('PIN PERMAINAN'), findsOneWidget);
      expect(find.text('NAMA PANGGILAN'), findsOneWidget);
      expect(find.text('GABUNG'), findsOneWidget);
      expect(find.text('1,240+ orang sedang bermain saat ini'), findsOneWidget);
    });

    testWidgets('tetap rapi pada layar sempit 320px', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_wrap(const EnterPinPage()));
      await tester.pump();

      expect(find.text('GABUNG'), findsOneWidget);
      expect(tester.takeException(), isNull);
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
