import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;

  const AppTabBar({super.key, required this.tabs});

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.metric.copyWith(color: null);

    return TabBar(
      isScrollable: false,
      indicatorSize: TabBarIndicatorSize.tab,
      labelColor: AppColors.primaryDark,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.primaryDark,
      labelStyle: labelStyle,
      unselectedLabelStyle: labelStyle,
      tabs: [
        for (final tab in tabs)
          Tab(
            child: FittedBox(fit: BoxFit.scaleDown, child: Text(tab)),
          ),
      ],
    );
  }
}
