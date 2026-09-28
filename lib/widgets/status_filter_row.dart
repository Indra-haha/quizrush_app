import 'package:flutter/material.dart';

import '../theme/quiz_status.dart';
import 'status_filter_chip.dart';

/// Baris chip filter status. Halaman cukup mengoper daftar status dan status
/// yang sedang aktif; pemetaan status ke label tetap di [QuizStatus].
class StatusFilterRow extends StatelessWidget {
  final List<String> statuses;
  final String selected;
  final ValueChanged<String> onChanged;
  final double spacing;

  const StatusFilterRow({
    super.key,
    required this.statuses,
    required this.selected,
    required this.onChanged,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < statuses.length; i++) ...[
          if (i > 0) SizedBox(width: spacing),
          StatusFilterChip(
            label: QuizStatus.labelOf(statuses[i]),
            selected: selected == statuses[i],
            onTap: () => onChanged(statuses[i]),
          ),
        ],
      ],
    );
  }
}
