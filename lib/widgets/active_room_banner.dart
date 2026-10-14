import 'package:flutter/material.dart';

import '../models/room.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'app_primary_button.dart';
import 'status_badge.dart';

/// Kartu "ROOM AKTIF" di atas daftar kuis. Menampilkan PIN room terakhir yang
/// sudah diverifikasi beserta tombol untuk masuk kembali ke ruang tunggu tanpa
/// mengetik PIN lagi.
class ActiveRoomBanner extends StatelessWidget {
  final Room room;
  final bool loading;
  final VoidCallback onEnter;
  final VoidCallback onDismiss;

  const ActiveRoomBanner({
    super.key,
    required this.room,
    this.loading = false,
    required this.onEnter,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space7),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ROOM AKTIF', style: AppTextStyles.accentLabel),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      formatKode(room.kode),
                      style: AppTextStyles.code.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      room.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: room.status),
              IconButton(
                tooltip: 'Lupakan room',
                onPressed: loading ? null : onDismiss,
                icon: const Icon(
                  Icons.close,
                  size: AppIconSize.sm,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space5),
          AppPrimaryButton(
            label: 'Masuk Room',
            icon: Icons.meeting_room_outlined,
            loading: loading,
            loadingLabel: 'Masuk...',
            onPressed: onEnter,
          ),
        ],
      ),
    );
  }
}
