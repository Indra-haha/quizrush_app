import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/utils/konversi_format.dart';

void main() {
  group('CalendarUtils.hitungUmur', () {
    test('menghitung tahun, bulan, dan hari', () {
      final umur = CalendarUtils.hitungUmur(
        DateTime(2000, 1, 1),
        DateTime(2005, 6, 15),
      );
      expect(umur['tahun'], 5);
      expect(umur['bulan'], 5);
      expect(umur['hari'], 14);
    });

    test('meminjam hari dari bulan sebelumnya', () {
      final umur = CalendarUtils.hitungUmur(
        DateTime(2000, 1, 20),
        DateTime(2000, 2, 10),
      );
      expect(umur['tahun'], 0);
      expect(umur['bulan'], 0);
      expect(umur['hari'], 21);
    });
  });

  group('CalendarUtils.wetonDari', () {
    test('1 Januari 1970 adalah hari Kamis', () {
      expect(CalendarUtils.wetonDari(DateTime(1970, 1, 1)), startsWith('Kamis'));
    });

    test('memetakan hari dalam sepekan', () {
      expect(CalendarUtils.wetonDari(DateTime(2026, 1, 1)), startsWith('Kamis'));
      expect(CalendarUtils.wetonDari(DateTime(2026, 1, 5)), startsWith('Senin'));
    });
  });

  group('CalendarUtils.formatSakaBali', () {
    test('mengurangi 78 tahun dari tahun Masehi', () {
      expect(
        CalendarUtils.formatSakaBali(DateTime(2026, 3, 1)),
        contains('Tahun Saka Bali: 1948'),
      );
    });
  });

  group('CalendarUtils.formatHijriah', () {
    test('berformat "<hari> <bulan> <tahun> H"', () {
      final hasil = CalendarUtils.formatHijriah(DateTime(2026, 3, 1));
      expect(hasil, endsWith(' H'));
      expect(hasil, matches(RegExp(r'^\d+ \w+( \w+)* \d+ H$')));
    });
  });
}
