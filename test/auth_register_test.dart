import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/pages/regis_page.dart';
import 'package:quizrush/theme/app_theme.dart';
import 'package:quizrush/widgets/auth_fields.dart';
import 'package:quizrush/widgets/auth_page.dart';

Widget _wrap() {
  return const MaterialApp(home: RegisterPage());
}

Future<void> _openPage(WidgetTester tester) async {
  tester.view.physicalSize = const Size(430, 1500);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(_wrap());
  await tester.pumpAndSettle();
}

Future<void> _fillForm(WidgetTester tester) async {
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'Budi Santoso');
  await tester.enterText(fields.at(1), '123456');
  await tester.enterText(fields.at(2), 'Pemrograman Mobile SI-B');
  await tester.enterText(fields.at(4), 'rahasia123');
  await tester.enterText(fields.at(5), 'rahasia123');
  await tester.pump();

  // Field tanggal lahir bersifat readOnly, jadi dipilih lewat date picker.
  await tester.tap(fields.at(3));
  await tester.pumpAndSettle();
  await tester.tap(find.text('10').last);
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  group('RegisterPage', () {
    testWidgets('menampilkan hero, wordmark, judul, dan seluruh field', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      expect(find.byType(AuthHeroPanel), findsOneWidget);
      expect(find.text('QUIZRUSH'), findsOneWidget);
      expect(
        find.text('Mulai petualangan cerdasmu sekarang!'),
        findsOneWidget,
      );
      expect(find.text('Buat Akun'), findsOneWidget);
      expect(find.text('Nama Lengkap'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Sekolahan'), findsOneWidget);
      expect(find.text('Tanggal Lahir'), findsOneWidget);
      expect(find.text('Kata Sandi'), findsOneWidget);
      expect(find.text('Konfirmasi Kata Sandi'), findsOneWidget);
      expect(find.text('Daftar'), findsOneWidget);
      expect(find.text('Sudah punya akun? '), findsOneWidget);
      expect(find.text('Masuk di sini'), findsOneWidget);
    });

    testWidgets('field kelas digantikan label sekolahan', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      expect(find.text('Sekolahan'), findsOneWidget);
      expect(find.text('Kelas'), findsNothing);
      expect(find.text('Sekolah'), findsNothing);
    });

    testWidgets('menampilkan teks syarat dan kebijakan privasi', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      expect(
        find.textContaining('Syarat & Ketentuan', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Kebijakan Privasi', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('setiap field punya ikon dan margin kiri', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      final fields = find.byType(AuthField);
      expect(tester.widgetList<AuthField>(fields).length, 6);

      double? iconLeft;
      for (var i = 0; i < 6; i++) {
        final field = tester.widget<AuthField>(fields.at(i));
        expect(
          field.icon,
          isNotNull,
          reason: 'field "${field.label}" harus punya ikon',
        );

        final box = tester.getRect(
          find.descendant(of: fields.at(i), matching: find.byType(Container)).first,
        );
        final input = tester.getRect(
          find.descendant(of: fields.at(i), matching: find.byType(TextField)),
        );
        expect(
          input.left - box.left,
          greaterThan(0),
          reason: 'field "${field.label}" harus punya margin kiri',
        );

        final icon = tester.getRect(
          find.descendant(of: fields.at(i), matching: find.byType(Icon)).first,
        );
        expect(
          icon.left - box.left,
          greaterThan(0),
          reason: 'ikon field "${field.label}" harus punya space kiri',
        );
        iconLeft ??= icon.left;
        expect(
          icon.left,
          iconLeft,
          reason: 'ikon semua field harus sejajar',
        );
      }
    });

    testWidgets('form kosong menampilkan pesan semua field wajib diisi', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      await tester.ensureVisible(find.text('Daftar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(find.text('Semua field wajib diisi'), findsOneWidget);
    });

    testWidgets('belum menyetujui syarat pendaftaran', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);
      await _fillForm(tester);

      await tester.ensureVisible(find.text('Daftar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daftar'));
      await tester.pump();

      expect(
        find.text(
          'Kamu harus menyetujui Syarat & Ketentuan serta Kebijakan Privasi',
        ),
        findsOneWidget,
      );
    });

    testWidgets('checkbox syarat bisa dicentang', (WidgetTester tester) async {
      await _openPage(tester);

      expect(find.byIcon(Icons.check), findsNothing);

      await tester.ensureVisible(find.byType(AuthTermsCheckbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AuthTermsCheckbox));
      await tester.pump();

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tombol daftar memakai gradien brand', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      final button = tester.widget<AuthSubmitButton>(
        find.byType(AuthSubmitButton),
      );
      expect(button.gradient, isTrue);

      final gradients = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<ShapeDecoration>()
          .where((decoration) => decoration.gradient != null)
          .map((decoration) => decoration.gradient! as LinearGradient)
          .toList();

      expect(
        gradients.any(
          (gradient) => gradient.colors == AppGradients.authAction.colors,
        ),
        isTrue,
      );
    });

    testWidgets('tautan masuk di sini menutup halaman register', (
      WidgetTester tester,
    ) async {
      await _openPage(tester);

      await tester.ensureVisible(find.text('Masuk di sini'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Masuk di sini'));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsNothing);
    });
  });
}
