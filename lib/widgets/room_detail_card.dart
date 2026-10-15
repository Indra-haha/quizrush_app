import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../models/quiz.dart';
import '../theme/app_theme.dart';
import '../theme/quiz_status.dart';
import 'app_pill.dart';
import 'app_primary_button.dart';

/// Kartu satu room pada halaman detail kuis (sisi peserta).
///
/// [isFocused] menyorot room yang cocok dengan PIN yang baru dimasukkan.
class RoomDetailCard extends StatelessWidget {
  final RoomSummary room;
  final int index;
  final bool isFocused;
  final VoidCallback? onJoin;

  const RoomDetailCard({
    super.key,
    required this.room,
    required this.index,
    required this.isFocused,
    this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final palette = QuizStatus.palette(room.status);
    final statusLabel = QuizStatus.labelOf(room.status);
    final subtitle = room.createdAt.isNotEmpty
        ? 'Dibuat ${relativeTime(room.createdAt)}'
        : 'Room #${index + 1}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        border: isFocused
            ? Border.all(color: AppColors.primary, width: AppBorderWidth.thin)
            : null,
        boxShadow: AppShadows.hairlineWide,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: palette.fg,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Text(
                  statusLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.statLabelOnPrimary.copyWith(
                    color: palette.fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          if (isFocused) ...[
            const AppPill(
              text: 'Room dari PIN yang kamu masukkan',
              background: AppColors.primarySoft,
              foreground: AppColors.textPrimary,
              icon: Icons.pin,
            ),
            const SizedBox(height: AppSpacing.space6),
          ],
          Text(room.judul, style: AppTextStyles.heading6),
          const SizedBox(height: AppSpacing.space3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.space8),
          if (room.kode.isNotEmpty || room.status == 'open')
            Container(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space6,
                AppSpacing.space8,
                AppSpacing.space6,
                AppSpacing.space6,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.lg,
              ),
              child: Row(
                children: [
                  // Feed publik tidak mengembalikan PIN; sembunyikan blok ini
                  // dan biarkan user memverifikasi lewat alur "Masuk".
                  if (room.kode.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('PIN SERVER', style: AppTextStyles.bodyMeta),
                        const SizedBox(height: AppSpacing.space1),
                        Text(
                          formatKode(room.kode),
                          style: AppTextStyles.display2.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  const Spacer(),
                  if (room.status == 'open')
                    SizedBox(
                      height: 44,
                      child: AppPrimaryButton(
                        label: 'Masuk',
                        radius: 12,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space10,
                        ),
                        onPressed: onJoin,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
