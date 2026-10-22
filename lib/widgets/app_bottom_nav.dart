import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Satu entri pada navigasi bawah.
class AppBottomNavItem {
  final String label;
  final IconData icon;

  const AppBottomNavItem({required this.label, required this.icon});
}

/// Navigasi bawah kustom.
///
/// Menggantikan `BottomNavigationBar` bawaan Material: bidang berwarna
/// surface dengan garis tepi 1px di luar bidang, bayangan tipis di bawahnya,
/// lalu ikon di atas label. Tab aktif ditandai lewat warna (primary),
/// tab lain memakai warna teks sekunder.
class AppBottomNav extends StatelessWidget {
  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: AppBorderWidth.hairline,
            strokeAlign: BorderSide.strokeAlignOutside,
            color: AppColors.primaryBorder,
          ),
        ),
        shadows: AppShadows.navBar,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space15),
            child: Row(
              spacing: AppSpacing.space5,
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(
                    child: _AppBottomNavEntry(
                      item: items[index],
                      isActive: index == currentIndex,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBottomNavEntry extends StatelessWidget {
  final AppBottomNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _AppBottomNavEntry({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.pill,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: AppIconSize.lg, color: color),
              const SizedBox(height: AppSpacing.space2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.navLabel.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
