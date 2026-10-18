import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../pages/points_history_page.dart';
import '../services/points_store.dart';
import '../theme/app_theme.dart';

/// Indikator saldo poin untuk appbar. Nilainya mengikuti [PointsStore] dan
/// menyegarkan diri dari server saat pertama dibangun; ketuk untuk membuka
/// riwayat koin.
class PointsIndicator extends StatefulWidget {
  /// Bila true, tidak memicu refresh otomatis (dipakai saat halaman sudah
  /// menyegarkan sendiri).
  final bool autoRefresh;

  const PointsIndicator({super.key, this.autoRefresh = true});

  @override
  State<PointsIndicator> createState() => _PointsIndicatorState();
}

class _PointsIndicatorState extends State<PointsIndicator> {
  @override
  void initState() {
    super.initState();
    if (widget.autoRefresh) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        PointsStore.instance.refresh();
      });
    }
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PointsHistoryPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PointsStore.instance,
      builder: (context, _) {
        final points = PointsStore.instance.points;
        final label = points == null ? '—' : formatPoints(points);

        return Tooltip(
          message: 'Poin kamu',
          child: InkWell(
            onTap: _openHistory,
            borderRadius: AppRadius.pill,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space5,
                vertical: AppSpacing.space3,
              ),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: AppRadius.pill,
                border: Border.all(
                  color: AppColors.primaryBorder.withValues(alpha: 0.5),
                  width: AppBorderWidth.hairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.emoji_events_rounded,
                    size: AppIconSize.sm,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Text(
                    label,
                    style: AppTextStyles.labelStrongSmall.copyWith(
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  Text(
                    'PTS',
                    style: AppTextStyles.bodyCaption.copyWith(
                      color: AppColors.primary,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
