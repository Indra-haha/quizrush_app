import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Baris pesan sistem (konek / join / leave) di ruang tunggu.
///
/// Murni presentational — teks sudah diformat oleh page.
class RoomSystemMessage extends StatelessWidget {
  final String text;

  const RoomSystemMessage({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space6,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppRadius.pill,
        ),
        child: Text(text, style: AppTextStyles.bodyCaption),
      ),
    );
  }
}

/// Bubble pesan chat pemain. Pesan milik sendiri rata kanan dan berwarna brand.
class RoomChatBubble extends StatelessWidget {
  final String from;
  final String text;
  final bool mine;

  const RoomChatBubble({
    super.key,
    required this.from,
    required this.text,
    required this.mine,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.space4),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space7,
          vertical: AppSpacing.space5,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? AppColors.primary : AppColors.textOnPrimary,
          borderRadius: AppRadius.lg,
          boxShadow: AppShadows.hairline,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) ...[
              Text(from, style: AppTextStyles.accentCaption),
              const SizedBox(height: AppSpacing.space1),
            ],
            Text(
              text,
              style: AppTextStyles.bodyMedium.copyWith(
                color: mine ? AppColors.textOnPrimary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
