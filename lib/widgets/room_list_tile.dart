import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import 'status_badge.dart';

/// Baris kartu satu room pada daftar room milik sebuah kuis.
class RoomListTile extends StatelessWidget {
  final RoomSummary room;
  final int index;
  final String quizTitle;
  final VoidCallback onTap;

  const RoomListTile({
    super.key,
    required this.room,
    required this.index,
    required this.quizTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: AppRadius.md,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    child: Text('${index + 1}'),
                  ),
                  const SizedBox(width: AppSpacing.space6),
                  Expanded(
                    child: Text(
                      room.kode,
                      style: AppTextStyles.metricStrong.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (room.status.isNotEmpty)
                    StatusBadge(status: room.status, dense: true),
                ],
              ),
              if (quizTitle.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(quizTitle, style: AppTextStyles.bodyMeta),
              ],
              if (room.createdAt.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.space3),
                Text(
                  relativeTime(room.createdAt),
                  style: AppTextStyles.metric,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
