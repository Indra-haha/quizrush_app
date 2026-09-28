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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutralBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
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
                  padding: const EdgeInsets.only(right: 12),
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
                      const SizedBox(height: 12),
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
                  const SizedBox(width: 6),
                  _copyButton(context),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

            // Bagian Bawah (Tombol Test di Kiri dan Tombol Check di Kanan)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 10),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(width: 1, color: AppColors.lineLight),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Tombol Test
                  if (room.status == "waiting" || room.status == "ended") GestureDetector(
                    onTap: onTestPressed,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.neutralBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.neutralBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.preview,
                            size: 14,
                            color: AppColors.neutralDark,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Preview',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodyMeta.copyWith(
                              color: AppColors.neutralDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Check (Monitor)
                  Material(
                    color: AppColors.successDark,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.checklist,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Check',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyMeta.copyWith(
                                color: Colors.white,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.neutralBorder),
      ),
      child: Text(
        room.kode,
        style: const TextStyle(
          color: AppColors.ink,
          fontSize: 12,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w900,
          height: 1.33,
          letterSpacing: 0.60,
        ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.softBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy, size: 14, color: AppColors.brandDeep),
            const SizedBox(width: 4),
            Text(
              'Salin',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMeta.copyWith(
                color: AppColors.brandDeep,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
