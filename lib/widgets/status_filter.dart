import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StatusFilterItem<T> {
  const StatusFilterItem({required this.value, required this.label});

  final T value;
  final String label;
}

class StatusFilter<T> extends StatelessWidget {
  const StatusFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    this.items,
    this.values,
    this.labels,
    this.labelBuilder,
    this.defaultLabels = const {
      'kecamatan': 'Kecamatan',
      'kota': 'Kota/Kab',
      'provinsi': 'Provinsi',
    },
    this.padding = EdgeInsets.zero,
    this.scrollable = true,
  }) : assert(
         items != null || values != null,
         'Either items or values must be provided',
       );

  final List<StatusFilterItem<T>>? items;
  final List<T>? values;
  final Map<T, String>? labels;
  final String Function(T value)? labelBuilder;
  final Map<Object, String> defaultLabels;
  final T selected;
  final ValueChanged<T> onChanged;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  List<StatusFilterItem<T>> get _resolvedItems {
    if (items != null) return items!;
    final list = values!;
    return [
      for (final v in list)
        StatusFilterItem<T>(
          value: v,
          label:
              labels?[v] ??
              labelBuilder?.call(v) ??
              (defaultLabels.containsKey(v) ? defaultLabels[v]! : v.toString()),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolvedItems;

    final pillBackground = AppColors.fieldBackground;
    final selectedBackground = AppColors.primary;
    final selectedForeground = AppColors.textOnPrimary;
    final unselectedForeground = AppColors.textPrimary;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in resolved)
          _StatusFilterTab(
            label: item.label,
            selected: item.value == selected,
            onTap: () => onChanged(item.value),
            selectedBackground: selectedBackground,
            selectedForeground: selectedForeground,
            unselectedForeground: unselectedForeground,
          ),
      ],
    );

    final Widget tabContent = scrollable
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: row,
          )
        : row;

    final Widget content = Container(
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: pillBackground,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 2, color: AppColors.divider),
          borderRadius: BorderRadius.circular(9999),
        ),
      ),
      child: tabContent,
    );

    return Padding(
      padding: padding,
      child: Center(child: content),
    );
  }
}

class _StatusFilterTab extends StatelessWidget {
  const _StatusFilterTab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.selectedBackground,
    required this.selectedForeground,
    required this.unselectedForeground,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedBackground;
  final Color selectedForeground;
  final Color unselectedForeground;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: ShapeDecoration(
          color: selected ? selectedBackground : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: Text(
          label,
          style: selected ? AppTextStyles.bodyMediumOnPrimary : AppTextStyles.body
        ),
      ),
    );
  }
}
