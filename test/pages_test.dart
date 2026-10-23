import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/pages/Ranking/ranking_region_page.dart';
import 'package:quizrush/pages/Profiles/profile_page.dart';
import 'package:quizrush/pages/Saldo/saldo_page.dart';
import 'package:quizrush/services/api/api_client.dart';
import 'package:quizrush/services/api/points_service.dart';
import 'package:quizrush/services/profile_stats_service.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: child);
}

class _FakeProfileStatsService implements ProfileStatsService {
  @override
  Future<ProfileStats> load({required String nama}) async {
    return const ProfileStats(games: 12, accuracy: 87, points: 28450);
  }
}

PointsService _saldoService() {
  final client = MockClient((request) async {
    final body = switch (request.url.path) {
      '/api/me/points' => jsonEncode({
        'message': 'Saldo poin',
        'points': 28450,
      }),
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
    List<Map<String, Object>> kota = const [],
    List<Map<String, Object>> provinsi = const [],
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
        'data': {'kecamatan': kecamatan, 'kota': kota, 'provinsi': provinsi},
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
      await tester.pumpAndSettle();

      expect(find.text('Leaderboard Wilayah'), findsOneWidget);
      // Slug wilayah dinormalisasi lewat `formatRegionLabel`
      // (lihat lib/helpers/region_label.dart).
      expect(
        find.text('Pasteur, kota Bandung, provinsi Jabar'),
        findsOneWidget,
      );
      expect(find.text('Pasteur'), findsWidgets);
      expect(find.text('Bandung'), findsWidgets);
      expect(find.text('Jabar'), findsWidgets);
      final top3 = find.text('Top 3 Pasteur');
      await tester.scrollUntilVisible(
        top3,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-kecamatan'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(top3, findsOneWidget);
      final peringkat = find.text('Peringkat 4 – 5');
      await tester.scrollUntilVisible(
        peringkat,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-kecamatan'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(peringkat, findsOneWidget);
      expect(find.text('Arka Pratama'), findsOneWidget);
      expect(find.text('@faris'), findsOneWidget);
      expect(find.text('14.850'), findsOneWidget);

      final me = find.text('Kamu (Dimas Arya)');
      await tester.scrollUntilVisible(
        me,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-kecamatan'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(me, findsOneWidget);
      expect(find.text('@dimas'), findsOneWidget);
    });

    testWidgets('menampilkan grup kota dan provinsi dari cache', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'token',
        'auth_user': jsonEncode({'username': 'dimas', 'nama': 'Dimas Arya'}),
        ...locationCache(
          kecamatan: [entry(1, 'arka', 'Arka Pratama', 14850)],
          kota: [entry(1, 'budi', 'Budi Santoso', 4890)],
          provinsi: [entry(1, 'dewi', 'Dewi Lestari', 18200)],
        ),
      });

      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pumpAndSettle();

      final arka = find.text('Arka Pratama');
      await tester.scrollUntilVisible(
        arka,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-kecamatan'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(arka, findsOneWidget);
      expect(find.text('Top 1 Pasteur'), findsOneWidget);

      await tester.tap(find.text('Bandung').first);
      await tester.pumpAndSettle();
      final budi = find.text('Budi Santoso');
      await tester.scrollUntilVisible(
        budi,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey<String>('ranking-list-kota')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(budi, findsOneWidget);
      expect(find.text('Top 1 Bandung'), findsOneWidget);

      await tester.tap(find.text('Jabar').first);
      await tester.pumpAndSettle();
      final dewi = find.text('Dewi Lestari');
      await tester.scrollUntilVisible(
        dewi,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-provinsi'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(dewi, findsOneWidget);
      expect(find.text('Top 1 Jabar'), findsOneWidget);
    });

    testWidgets('menggeser halaman menyinkronkan tab aktif', (
      WidgetTester tester,
    ) async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'auth_token': 'token',
        ...locationCache(
          kecamatan: [entry(1, 'arka', 'Arka Pratama', 14850)],
          kota: [entry(1, 'budi', 'Budi Santoso', 4890)],
          provinsi: [entry(1, 'dewi', 'Dewi Lestari', 18200)],
        ),
      });

      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pumpAndSettle();

      expect(find.text('Top 1 Pasteur'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Top 1 Bandung'), findsOneWidget);
      final budi2 = find.text('Budi Santoso');
      await tester.scrollUntilVisible(
        budi2,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const PageStorageKey<String>('ranking-list-kota')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(budi2, findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(-600, 0));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Top 1 Jabar'), findsOneWidget);
      final dewi2 = find.text('Dewi Lestari');
      await tester.scrollUntilVisible(
        dewi2,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-provinsi'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(dewi2, findsOneWidget);
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
      await tester.pumpAndSettle();

      final peringkat13 = find.text('Peringkat 4 – 13');
      await tester.scrollUntilVisible(
        peringkat13,
        200,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-kecamatan'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(peringkat13, findsOneWidget);

      final me = find.text('Kamu (Dimas Arya)');
      await tester.scrollUntilVisible(
        me,
        300,
        scrollable: find
            .descendant(
              of: find.byKey(
                const PageStorageKey<String>('ranking-list-kecamatan'),
              ),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(me, findsOneWidget);
    });

    testWidgets('menampilkan pesan kosong tanpa data lokasi', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(const RankingRegionPage()));
      await tester.pump();

      expect(find.text('Leaderboard Wilayah'), findsOneWidget);
      expect(find.text('Kecamatan, Kota, Provinsi'), findsOneWidget);
      expect(find.text('Belum ada data peringkat wilayah.'), findsOneWidget);
      expect(find.text('Peringkat 4 – 0'), findsNothing);
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
    testWidgets('menampilkan data user, statistik, dan logout di header', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          ProfilePage(
            user: const {
              'nama': 'Budi Santoso',
              'username': 'budi',
              'kelas': 'XI IPA 1',
              'tanggal_lahir': '17/08/2006',
            },
            statsService: _FakeProfileStatsService(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsWidgets);
      expect(find.text('BS'), findsOneWidget);
      expect(find.text('@budi'), findsOneWidget);
      expect(find.text('XI IPA 1'), findsOneWidget);
      expect(find.text('2006-08-17'), findsNothing);

      expect(find.text('Game'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Akurasi'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
      expect(find.text('Saldo Koin'), findsOneWidget);
      expect(find.text('28.450'), findsOneWidget);

      expect(find.byTooltip('Keluar'), findsOneWidget);
      expect(find.text('Keluar'), findsNothing);
    });
  });
}
