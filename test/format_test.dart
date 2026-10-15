import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/models/quiz.dart';
import 'package:quizrush/helpers/format.dart';

Quizes _quiz(List<double> durations) {
  return Quizes(
    id: 'q1',
    userId: 'u1',
    title: 'Kuis',
    description: 'Deskripsi',
    createdAt: '2026-09-17T10:00:00Z',
    questions: [
      for (final d in durations)
        QuizQuestion(question: 'q', options: const ['a'], duration: d),
    ],
  );
}

void main() {
  group('totalDuration', () {
    test('menjumlahkan durasi semua pertanyaan', () {
      expect(totalDuration(_quiz([1.5, 2.0, 3.0])), 6.5);
      expect(totalDuration(_quiz([])), 0);
    });
  });

  group('formatDuration', () {
    test('di bawah satu menit memakai Detik', () {
      expect(formatDuration(45), '45 Detik');
    });

    test('kelipatan menit tanpa Detik', () {
      expect(formatDuration(120), '2 Menit');
    });

    test('menit dan detik', () {
      expect(formatDuration(125), '2 Menit 5 Detik');
    });
  });

  group('formatQDuration', () {
    test('bulat tanpa desimal', () {
      expect(formatQDuration(3), '3 Detik');
    });

    test('pecahan satu desimal', () {
      expect(formatQDuration(1.5), '1.5 Detik');
    });
  });

  group('formatKode', () {
    test('memisahkan 6 digit jadi dua grup', () {
      expect(formatKode('123456'), '123 456');
    });

    test('mengembalikan apa adanya kalau bukan 6 digit', () {
      expect(formatKode('12345'), '12345');
    });
  });

  group('formatTanggalLahir', () {
    test('mengubah d/m/y jadi y-m-d', () {
      expect(formatTanggalLahir('5/3/2005'), '2005-03-05');
    });

    test('tidak valid dikembalikan apa adanya', () {
      expect(formatTanggalLahir('bukan-tanggal'), 'bukan-tanggal');
      expect(formatTanggalLahir('a/b/c'), 'a/b/c');
    });
  });

  group('parseTimeOrEpoch', () {
    test('parse waktu ISO', () {
      expect(
        parseTimeOrEpoch('2026-09-17T10:00:00Z'),
        DateTime.parse('2026-09-17T10:00:00Z'),
      );
    });

    test('fallback epoch kalau tidak valid', () {
      expect(
        parseTimeOrEpoch('ngawur'),
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
  });

  group('relativeTime', () {
    test('mengembalikan raw kalau tidak bisa diparse', () {
      expect(relativeTime('ngawur'), 'ngawur');
    });

    test('baru saja untuk waktu sekarang', () {
      final now = DateTime.now().toIso8601String();
      expect(relativeTime(now), 'Baru saja');
    });

    test('menghitung hari lalu', () {
      final raw = DateTime.now()
          .subtract(const Duration(days: 3))
          .toIso8601String();
      expect(relativeTime(raw), '3 Hari lalu');
    });
  });
}
