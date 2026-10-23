import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/create_quiz_theme.dart';

String _formatDurationOption(dynamic value) {
  if (value is num) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    final text = value.toString();
    // Pastikan menggunakan titik, bukan koma
    return text.replaceAll(',', '.');
  }
  final text = value.toString();
  return text.replaceAll(',', '.');
}

class AppOptionsSelect extends StatelessWidget {
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const AppOptionsSelect({
    super.key,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: CreateQuizQuestionStyles.durationChipPadding,
        decoration: selected
            ? CreateQuizQuestionStyles.durationChipSelectedDecoration
            : CreateQuizQuestionStyles.durationChipDecoration,
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: selected
              ? CreateQuizTextStyles.durationSelected
              : CreateQuizTextStyles.duration,
        ),
      ),
    );
  }
}

class ListOptions<T> extends StatelessWidget {
  final List<T> optionLists;
  final T selectedOption;
  final ValueChanged<T> onSelectedChange;

  const ListOptions({
    super.key,
    required this.optionLists,
    required this.selectedOption,
    required this.onSelectedChange,
  });

  @override
  Widget build(BuildContext context) {
    // Bungkus dengan Align agar kontainer tidak ikut melebar memenuhi parent (Expanded)
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: CreateQuizQuestionStyles.durationTrackPadding,
        decoration: CreateQuizQuestionStyles.durationTrackDecoration,
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Membuat Row hanya memakan lebar sesuai isi anak
          children: [
            for (var i = 0; i < optionLists.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.space1),
              AppOptionsSelect(
                value: _formatDurationOption(optionLists[i]),
                selected: optionLists[i] == selectedOption,
                onTap: () => onSelectedChange(optionLists[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}