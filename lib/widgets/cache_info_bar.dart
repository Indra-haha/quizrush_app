import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../helpers/format.dart';

/// Baris informasi kecil di bawah kolom pencarian.
///
/// Dua mode, bukan dua widget:
/// - [pinProgress] diisi 1-5 saat pengguna sedang mengetik PIN, lalu baris ini
///   menjadi penghitung progres alih-alih teks cache.
/// - [savedAt] diisi kalau ada cache lokal, untuk memberi tahu data age.
///
/// Widget ini hanya menerima [DateTime] dan [int] supaya `widgets/` tidak pernah
/// bergantung pada `services/`.
class CacheInfoBar extends StatelessWidget {
  final DateTime? savedAt;
  final int? pinProgress;
  final String savedAtLabel;

  const CacheInfoBar({
    super.key,
    this.savedAt,
    this.pinProgress,
    this.savedAtLabel = 'Dari cache perangkat. Terakhir diperbarui',
  });

  @override
  Widget build(BuildContext context) {
    final progress = pinProgress;
    if (progress != null) {
      return _row(
        icon: Icons.pin_outlined,
        text: 'PIN room: $progress dari 6 digit.',
      );
    }

    final at = savedAt;
    if (at == null) return const SizedBox.shrink();

    return _row(
      icon: Icons.offline_bolt_outlined,
      text: '$savedAtLabel ${relativeTime(at.toIso8601String())}.',
    );
  }

  Widget _row({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: AppIconSize.micro, color: AppColors.info),
        const SizedBox(width: AppSpacing.space2),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyCaption.copyWith(color: AppColors.info),
          ),
        ),
      ],
    );
  }
}
