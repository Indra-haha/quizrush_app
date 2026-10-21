import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/helpers/region_label.dart';

void main() {
  group('formatRegionLabel', () {
    test('membuang kata administratif dan memformat slug wilayah', () {
      expect(
        formatRegionLabel('kecamatan-pasteur, kota-bandung, provinsi-jabar'),
        'Pasteur, kota Bandung, provinsi Jabar',
      );
    });

    test('mengubah singkatan pendek menjadi kapital semua', () {
      expect(formatRegionLabel('provinsi-diy'), 'DIY');
      expect(formatRegionLabel('kota-yogyakarta'), 'Yogyakarta');
    });

    test('mengembalikan string kosong untuk input kosong', () {
      expect(formatRegionLabel(''), '');
      expect(formatRegionLabel('   '), '');
      expect(formatRegionLabel('kota'), '');
    });
  });
}
