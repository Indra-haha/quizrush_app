import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/pages/Ranking/ranking_region_page.dart';
import 'package:quizrush/services/api/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Map<String, dynamic> _mockLocationJson = {
  'status': 200,
  'message': 'Grouped leaderboard successfully retrieved',
  'metadata': {
    'user_location': {'latitude': -7.79558, 'longitude': 110.36949},
    'resolved_regions': {
      'kecamatan': 'kecamatan-depok',
      'kota': 'kota-sleman',
      'provinsi': 'provinsi-diy',
    },
    'timestamp': '2026-10-20T06:30:00Z',
  },
  'data': {
    'kecamatan': [
      {
        'rank': 1,
        'username': 'ahmad',
        'nama': 'Ahmad',
        'poin': 1450,
        'jarak_meter': 350.2,
      },
      {
        'rank': 2,
        'username': 'siti',
        'nama': 'Siti',
        'poin': 1200,
        'jarak_meter': 700.5,
      },
    ],
    'kota': [
      {
        'rank': 1,
        'username': 'budi',
        'nama': 'Budi',
        'poin': 4890,
        'jarak_meter': 4500.0,
      },
    ],
    'provinsi': [
      {
        'rank': 1,
        'username': 'dewi',
        'nama': 'Dewi',
        'poin': 18200,
        'jarak_meter': 12500.0,
      },
    ],
  },
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'RankingRegionPage saat lokasi belum aktif menampilkan banner tidak aktif dan tombol aktifkan',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(home: RankingRegionPage(isActive: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Leaderboard Wilayah'), findsOneWidget);
      expect(find.text('Lokasi Wilayah Dinonaktifkan'), findsOneWidget);
      expect(find.text('Aktifkan'), findsOneWidget);
      expect(find.text('Lokasi Belum Diaktifkan'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Aktifkan Lokasi'), findsOneWidget);
    },
  );

  testWidgets(
    'RankingRegionPage saat lokasi aktif menggunakan cache dan tidak meminta ulang saat berganti tab',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues(<String, Object>{
        'region_location': jsonEncode({
          'version': 2,
          'savedAt': DateTime.now().toIso8601String(),
          'result': _mockLocationJson,
        }),
        'region_location_enabled': true,
      });

      await tester.pumpWidget(
        const MaterialApp(home: RankingRegionPage(isActive: true)),
      );
      await tester.pumpAndSettle();

      // Wilayah dari metadata harus muncul di banner
      expect(find.textContaining('Depok, Sleman, DIY'), findsOneWidget);
      expect(find.text('Ubah'), findsOneWidget);
      expect(find.text('Top 2 Depok'), findsOneWidget);

      // Simulasikan berpindah tab (isActive false lalu true lagi)
      await tester.pumpWidget(
        const MaterialApp(home: RankingRegionPage(isActive: false)),
      );
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        const MaterialApp(home: RankingRegionPage(isActive: true)),
      );
      await tester.pumpAndSettle();

      // Tetap menampilkan lokasi yang sama dan aktif tanpa prompt ulang
      expect(find.textContaining('Depok, Sleman, DIY'), findsOneWidget);
      expect(find.text('Top 2 Depok'), findsOneWidget);
    },
  );

  testWidgets(
    'RankingRegionPage menekan tombol Ubah lalu Matikan Lokasi menonaktifkan lokasi dan menghapus cache',
    (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues(<String, Object>{
        'region_location': jsonEncode({
          'version': 2,
          'savedAt': DateTime.now().toIso8601String(),
          'result': _mockLocationJson,
        }),
        'region_location_enabled': true,
      });

      await tester.pumpWidget(
        const MaterialApp(home: RankingRegionPage(isActive: true)),
      );
      await tester.pumpAndSettle();

      // Ketuk tombol Ubah
      final ubahFinder = find.text('Ubah');
      expect(ubahFinder, findsOneWidget);
      await tester.tap(ubahFinder);
      await tester.pumpAndSettle();

      // Bottom sheet opsi muncul
      expect(find.text('Pengaturan Lokasi Wilayah'), findsOneWidget);
      expect(find.text('Perbarui Lokasi'), findsOneWidget);
      expect(find.text('Matikan Lokasi'), findsOneWidget);

      // Ketuk Matikan Lokasi
      await tester.tap(find.text('Matikan Lokasi'));
      await tester.pumpAndSettle();

      // Banner dan empty hint berubah menjadi tidak aktif
      expect(find.text('Lokasi Wilayah Dinonaktifkan'), findsOneWidget);
      expect(find.text('Aktifkan'), findsOneWidget);
      expect(await LocationService.instance.isEnabled(), isFalse);
    },
  );
}

