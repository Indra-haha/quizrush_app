import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Tampilan untuk daftar yang kosong atau sedang dalam kondisi tertentu.
///
/// Konsumen tidak lagi menyuntik [TextStyle] sendiri; setiap kondisi punya
/// named constructor sehingga gayanya terkunci di satu tempat.
enum EmptyStateKind { empty, noResult, searching, notFound, error }

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? caption;
  final EmptyStateKind kind;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.message,
    this.caption,
    this.kind = EmptyStateKind.empty,
  });

  const EmptyStateView.empty({super.key, this.message = 'Belum ada quiz.'})
    : icon = Icons.quiz_outlined,
      caption = null,
      kind = EmptyStateKind.empty;

  const EmptyStateView.error(this.message, {super.key, this.caption})
    : icon = Icons.error_outline,
      kind = EmptyStateKind.error;

  factory EmptyStateView.noResult(String query) {
    return EmptyStateView(
      icon: Icons.search_off,
      message: 'Tidak ada hasil untuk "$query".',
      kind: EmptyStateKind.noResult,
    );
  }

  factory EmptyStateView.searching(int progress) {
    return EmptyStateView(
      icon: Icons.pin_outlined,
      message: 'Sedang mencari room',
      caption: '$progress dari 6 digit',
      kind: EmptyStateKind.searching,
    );
  }

  const EmptyStateView.notFound({super.key})
    : icon = Icons.pin_outlined,
      message = 'Room tidak ditemukan',
      caption = 'Tekan refresh bila room baru dibuat.',
      kind = EmptyStateKind.notFound;

  @override
  Widget build(BuildContext context) {
    final style = switch (kind) {
      EmptyStateKind.searching || EmptyStateKind.notFound =>
        GoogleFonts.plusJakartaSans(
          color: AppColors.ink,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      _ => GoogleFonts.plusJakartaSans(color: AppColors.muted, fontSize: 14),
    };

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kind == EmptyStateKind.searching)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            Icon(icon, size: 48, color: AppColors.neutral),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(message, textAlign: TextAlign.center, style: style),
          ),
          if (caption != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                caption!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyCaption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
