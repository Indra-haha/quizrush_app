import 'package:flutter/material.dart';

import '../theme/quiz_status.dart';
import '../theme/app_theme.dart';

/// Badge status room dengan warna dari [QuizStatus.palette], jadi badge ini dan
/// pil di halaman detail room tidak pernah berbeda warna untuk status yang sama.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool dense;

  const StatusBadge({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final palette = QuizStatus.palette(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.space4 : AppSpacing.space6,
        vertical: dense ? AppSpacing.space1 : AppSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: AppRadius.md,
        border: Border.all(color: palette.border),
      ),
      child: Text(
        QuizStatus.labelOf(status),
        style: AppTextStyles.statLabelOnPrimary.copyWith(color: palette.fg),
      ),
    );
  }
}
