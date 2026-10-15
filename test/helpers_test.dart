import 'package:flutter_test/flutter_test.dart';
import 'package:quizrush/helpers/auth_validator.dart';
import 'package:quizrush/helpers/pin.dart';
import 'package:quizrush/helpers/quiz_form_validator.dart';
import 'package:quizrush/helpers/quiz_image.dart';
import 'package:quizrush/helpers/room_status_flow.dart';

QuizFormQuestion _q({String skor = '20', int? correctIdx = 0}) {
  return QuizFormQuestion(
    question: 'Berapa 2 + 2?',
    options: const ['3', '4', '5', '6'],
    correctIdx: correctIdx,
    skor: skor,
  );
}

void main() {  group('Pin', () {
    test('isComplete menerima tepat 6 digit', () {
      expect(Pin.isComplete('123456'), isTrue);
      expect(Pin.isComplete(' 123456 '), isTrue);
      expect(Pin.isComplete('12345'), isFalse);
      expect(Pin.isComplete('1234567'), isFalse);
      expect(Pin.isComplete('12a456'), isFalse);
      expect(Pin.isComplete(''), isFalse);
    });

    test('progress mengembalikan jumlah digit 1-5', () {
      expect(Pin.progress('1'), 1);
      expect(Pin.progress('12345'), 5);
      expect(Pin.progress(''), isNull);
      expect(Pin.progress('123456'), isNull);
      expect(Pin.progress('12a'), isNull);
    });
  });

  group('AuthValidator.login', () {
    test('valid saat username dan password terisi', () {
      expect(
        AuthValidator.login(username: 'budi', password: 'rahasia'),
        isNull,
      );
    });

    test('menolak field kosong', () {
      expect(
        AuthValidator.login(username: '  ', password: 'x'),
        'Username dan password wajib diisi',
      );
      expect(
        AuthValidator.login(username: 'budi', password: ''),
        'Username dan password wajib diisi',
      );
    });
  });

  group('AuthValidator.register', () {
    String? call({
      String nama = 'Budi',
      String username = 'budi',
      String kelas = '6A',
      String tanggalLahir = '2005-01-01',
      String password = 'rahasia',
      String confirmPassword = 'rahasia',
    }) {
      return AuthValidator.register(
        nama: nama,
        username: username,
        kelas: kelas,
        tanggalLahir: tanggalLahir,
        password: password,
        confirmPassword: confirmPassword,
      );
    }

    test('valid saat semua terisi dan password cocok', () {
      expect(call(), isNull);
    });

    test('menolak field kosong', () {
      expect(call(nama: '  '), 'Semua field wajib diisi');
      expect(call(tanggalLahir: ''), 'Semua field wajib diisi');
    });

    test('menolak password tidak cocok', () {
      expect(
        call(password: 'a', confirmPassword: 'b'),
        'Password tidak cocok',
      );
    });
  });

  group('RoomStatusFlow', () {
    test('next mengikuti urutan publish', () {
      expect(RoomStatusFlow.next('waiting'), 'open');
      expect(RoomStatusFlow.next('open'), 'in-Game');
      expect(RoomStatusFlow.next('in-Game'), 'ended');
      expect(RoomStatusFlow.next('ended'), isNull);
      expect(RoomStatusFlow.next('tidak-dikenal'), isNull);
    });

    test('publishMeta memberi label aksi sesuai status berikutnya', () {
      expect(RoomStatusFlow.publishMeta('open').$1, 'Publish');
      expect(RoomStatusFlow.publishMeta('in-Game').$1, 'Mulai Game');
      expect(RoomStatusFlow.publishMeta('ended').$1, 'Akhiri');
      expect(RoomStatusFlow.publishMeta(null).$1, 'Selesai');
    });
  });

  group('QuizImage', () {
    test('isWithinSizeLimit menerima sampai 5 MB', () {
      expect(QuizImage.isWithinSizeLimit(5 * 1024 * 1024), isTrue);
      expect(QuizImage.isWithinSizeLimit(5 * 1024 * 1024 + 1), isFalse);
    });

    test('filename memakai name kalau ada, jatuh ke path', () {
      expect(QuizImage.filename(name: 'foto.png', path: 'a/b.png'), 'foto.png');
      expect(QuizImage.filename(name: '  ', path: 'a/b/c.jpg'), 'c.jpg');
      expect(
        QuizImage.filename(name: '', path: r'C:\tmp\gambar.webp'),
        'gambar.webp',
      );
    });

    test('mediaType berdasarkan ekstensi', () {
      expect(QuizImage.mediaType('foto.jpg').subtype, 'jpeg');
      expect(QuizImage.mediaType('foto.JPEG').subtype, 'jpeg');
      expect(QuizImage.mediaType('foto.png').subtype, 'png');
      expect(QuizImage.mediaType('foto.webp').subtype, 'webp');
      expect(QuizImage.mediaType('berkas.gif').type, 'application');
    });
  });

  group('QuizFormValidator', () {
    String? validate({
      String title = 'Kuis',
      String description = 'Deskripsi',
      bool hasImage = true,
      int count = 5,
      QuizFormQuestion? question,
    }) {
      final questions = List.generate(count, (i) => question ?? _q());
      return QuizFormValidator.validate(
        title: title,
        description: description,
        hasImage: hasImage,
        questions: questions,
      );
    }

    test('valid saat lengkap', () {
      expect(validate(), isNull);
    });

    test('menolak judul/deskripsi/gambar kosong', () {
      expect(validate(title: '  '), 'Judul quiz wajib diisi.');
      expect(validate(description: ''), 'Deskripsi quiz wajib diisi.');
      expect(validate(hasImage: false), 'Gambar kuis wajib diunggah.');
    });

    test('menolak kurang dari 5 pertanyaan', () {
      expect(validate(count: 4), 'Minimal 5 pertanyaan.');
    });

    test('menolak pertanyaan kosong', () {
      expect(
        validate(
          question: const QuizFormQuestion(
            question: '  ',
            options: ['a', 'b', 'c', 'd'],
            correctIdx: 0,
            skor: '10',
          ),
        ),
        'Pertanyaan 1 wajib diisi.',
      );
    });

    test('menolak jawaban kosong', () {
      expect(
        validate(
          question: const QuizFormQuestion(
            question: 'q',
            options: ['a', '  ', 'c', 'd'],
            correctIdx: 0,
            skor: '10',
          ),
        ),
        'Jawaban 2 pada pertanyaan 1 wajib diisi.',
      );
    });

    test('menolak tanpa jawaban benar', () {
      expect(
        validate(question: _q(correctIdx: null)),
        'Pilih jawaban benar untuk pertanyaan 1.',
      );
    });

    test('menolak poin di luar 1-50', () {
      expect(
        validate(question: _q(skor: '0')),
        'Poin pertanyaan 1 harus berupa angka 1-50.',
      );
      expect(
        validate(question: _q(skor: '51')),
        'Poin pertanyaan 1 harus berupa angka 1-50.',
      );
      expect(
        validate(question: _q(skor: 'abc')),
        'Poin pertanyaan 1 harus berupa angka 1-50.',
      );
    });
  });
}
