import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/engine/kalkulator_engine.dart';

void main() {
  group('hitungSkorWaktu', () {
    test('jawaban salah selalu 0 poin', () {
      expect(
        KalkulatorEngine.hitungSkorWaktu(
          isBenar: false,
          elapsedMs: 0,
          maxDurationSec: 10,
          bobotMaks: 50,
        ),
        0,
      );
    });

    test('jawaban benar di akhir waktu minimal 5 poin', () {
      expect(
        KalkulatorEngine.hitungSkorWaktu(
          isBenar: true,
          elapsedMs: 9999,
          maxDurationSec: 10,
          bobotMaks: 50,
        ),
        5,
      );
    });

    test('jawaban benar seketika dapat poin penuh', () {
      expect(
        KalkulatorEngine.hitungSkorWaktu(
          isBenar: true,
          elapsedMs: 0,
          maxDurationSec: 10,
          bobotMaks: 50,
        ),
        50,
      );
    });

    test('poin proporsional terhadap sisa waktu', () {
      expect(
        KalkulatorEngine.hitungSkorWaktu(
          isBenar: true,
          elapsedMs: 5000,
          maxDurationSec: 10,
          bobotMaks: 50,
        ),
        25,
      );
    });

    test('elapsed melebihi durasi dianggap waktu habis', () {
      expect(
        KalkulatorEngine.hitungSkorWaktu(
          isBenar: true,
          elapsedMs: 12000,
          maxDurationSec: 10,
          bobotMaks: 50,
        ),
        0,
      );
    });
  });
}
