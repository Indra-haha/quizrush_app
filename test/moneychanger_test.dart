import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/helpers/moneychanger.dart';

void main() {
  group('convertMoney', () {
    test('IDR ke USD', () {
      expect(convertMoney(163000, 'IDR', 'USD'), closeTo(10, 1e-9));
    });

    test('USD ke IDR', () {
      expect(convertMoney(10, 'USD', 'IDR'), closeTo(163000, 1e-9));
    });

    test('lintas mata uang non-IDR (USD ke SGD)', () {
      expect(convertMoney(10, 'USD', 'SGD'), closeTo(163000 / 12100, 1e-9));
    });

    test('mata uang sama mengembalikan nilai asli', () {
      expect(convertMoney(42.5, 'USD', 'USD'), 42.5);
    });

    test('kode tidak peka huruf besar/kecil dan Rp = IDR', () {
      expect(convertMoney(163000, 'rp', 'usd'), closeTo(10, 1e-9));
    });

    test('kode tidak dikenal melempar ArgumentError', () {
      expect(() => convertMoney(1, 'IDR', 'XYZ'), throwsArgumentError);
      expect(() => convertMoney(1, 'XYZ', 'IDR'), throwsArgumentError);
    });
  });

  group('formatMoney', () {
    test('IDR tanpa desimal dan pemisah ribuan titik', () {
      expect(formatMoney(284500, 'IDR'), 'Rp 284.500');
    });

    test('USD dua desimal dengan koma', () {
      expect(formatMoney(18.5, 'USD'), r'$ 18,50');
    });

    test('nilai negatif', () {
      expect(formatMoney(-1500, 'IDR'), '-Rp 1.500');
    });

    test('JPY tanpa desimal', () {
      expect(formatMoney(10500, 'JPY'), '¥ 10.500');
    });

    test('kode tidak dikenal melempar ArgumentError', () {
      expect(() => formatMoney(1, 'XYZ'), throwsArgumentError);
    });
  });

  test('supportedCurrencies berisi kode yang didukung', () {
    expect(supportedCurrencies, containsAll(<String>['IDR', 'USD', 'JPY']));
  });
}
