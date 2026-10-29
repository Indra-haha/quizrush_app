import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/helpers/moneychanger.dart';

void main() {
  group('moneychanger', () {
    test('formatMoney without conversion', () {
      expect(formatMoney(284500, 'IDR'), 'Rp 284.500');
      expect(formatMoney(18.5, 'USD'), r'$ 18,50');
    });

    test('formatMoney with conversion (currently -> future)', () {
      // 43434 IDR to USD: 43434 / 16300 = 2.664... -> $ 2,66
      expect(formatMoney(43434, 'IDR', 'USD'), r'$ 2,66');
      // 10 USD to IDR: 10 * 16300 = 163000 -> Rp 163.000
      expect(formatMoney(10, 'USD', 'IDR'), 'Rp 163.000');
    });
  });
}
