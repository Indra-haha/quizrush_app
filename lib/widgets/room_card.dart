import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/quiz.dart';
import '../theme/app_theme.dart';
import 'app_snackbar.dart';

class RoomCard extends StatelessWidget {
  final Quizes quiz;
  final RoomSummary room;
  final VoidCallback? onTap;
  final VoidCallback? onTestPressed;

  const RoomCard({
    super.key,
    required this.quiz,
    required this.room,
    this.onTap,
    this.onTestPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space7),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Atas (Judul Quiz, Kode, dan Tombol Salin)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Menggunakan AppTextStyles.heading2 (Montserrat, 18px, w500)
                      Text(
                        room.judul,
                        style: AppTextStyles.heading2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.space6),
                      // Menggunakan AppTextStyles.bodyMeta (Plus Jakarta Sans, 12px, w600)
                      Text(quiz.title, style: AppTextStyles.bodyMeta),
                    ],
                  ),
                ),
              ),
              // Bagian Kanan Atas: Kode Chip & Tombol Salin
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _codeChip(),
                  const SizedBox(width: AppSpacing.space3),
                  _copyButton(context),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),

          // Bagian Bawah (Tombol Test di Kiri dan Tombol Check di Kanan)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: AppSpacing.space5),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(
                  width: AppBorderWidth.hairline,
                  color: AppColors.divider,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Tombol Test
                if (room.status == "waiting" || room.status == "ended")
                  GestureDetector(
                    onTap: onTestPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space6,
                        vertical: AppSpacing.space3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: AppRadius.md,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.preview,
                            size: AppIconSize.xs,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Text(
                            'Preview',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMeta.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(width: AppSpacing.space6),
                // Tombol Check (Monitor)
                Material(
                  color: AppColors.success,
                  borderRadius: AppRadius.md,
                  child: InkWell(
                    borderRadius: AppRadius.md,
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space8,
                        vertical: AppSpacing.space3,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.checklist,
                            size: AppIconSize.xs,
                            color: AppColors.textOnPrimary,
                          ),
                          const SizedBox(width: AppSpacing.space3),
                          Text(
                            'Check',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMeta.copyWith(
                              color: AppColors.textOnPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _codeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.divider),
      ),
      child: Text(room.kode, style: AppTextStyles.roomCode),
    );
  }

  Widget _copyButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: room.kode));
        AppSnackBar.show(
          context,
          'Kode room disalin.',
          duration: const Duration(seconds: 1),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.copy,
              size: AppIconSize.xs,
              color: AppColors.primaryDark,
            ),
            const SizedBox(width: AppSpacing.space2),
            Text(
              'Salin',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMeta.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
