import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quizrush/theme/app_theme.dart';
import 'package:quizrush/widgets/app_bottom_nav.dart';

const _items = <AppBottomNavItem>[
  AppBottomNavItem(label: 'Home', icon: Icons.home_rounded),
  AppBottomNavItem(label: 'Reward', icon: Icons.card_giftcard_rounded),
  AppBottomNavItem(label: 'Quiz', icon: Icons.quiz_rounded),
  AppBottomNavItem(label: 'Rank', icon: Icons.emoji_events_rounded),
  AppBottomNavItem(label: 'Profile', icon: Icons.person_rounded),
];

Widget _wrap({int currentIndex = 0, ValueChanged<int>? onSelected}) {
  return MaterialApp(
    home: Scaffold(
      bottomNavigationBar: AppBottomNav(
        items: _items,
        currentIndex: currentIndex,
        onSelected: onSelected ?? (_) {},
      ),
    ),
  );
}

void main() {
  group('AppBottomNav', () {
    testWidgets('menampilkan seluruh label tab', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap());

      for (final item in _items) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('tab aktif memakai warna primary, tab lain text sekunder', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap(currentIndex: 0));

      final active = tester.widget<Text>(find.text('Home'));
      final inactive = tester.widget<Text>(find.text('Quiz'));

      expect(active.style?.color, AppColors.primary);
      expect(inactive.style?.color, AppColors.textSecondary);
    });

    testWidgets('warna ikon mengikuti status tab', (WidgetTester tester) async {
      await tester.pumpWidget(_wrap(currentIndex: 2));

      expect(
        tester.widget<Icon>(find.byIcon(Icons.quiz_rounded)).color,
        AppColors.primary,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.home_rounded)).color,
        AppColors.textSecondary,
      );
    });

    testWidgets('dekorasi memakai nav surface dan shadow atas', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(_wrap());

      final box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(AppBottomNav),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final decoration = box.decoration as BoxDecoration;

      expect(decoration.color, AppColors.navSurface);
      expect(decoration.boxShadow, AppShadows.navBarUp);
      expect(decoration.border, isNull);
    });

    testWidgets('ketuk tab memanggil onSelected dengan index yang benar', (
      WidgetTester tester,
    ) async {
      final selected = <int>[];
      await tester.pumpWidget(_wrap(onSelected: selected.add));

      await tester.tap(find.text('Rank'));
      await tester.tap(find.text('Profile'));

      expect(selected, [3, 4]);
    });

    testWidgets('tidak meluber di layar kecil', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap());

      expect(tester.takeException(), isNull);
    });
  });
}
