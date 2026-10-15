import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Kotak pemilih gambar quiz: placeholder, pratinjau, dan tombol hapus.
///
/// Murni presentational — page yang mengurus `image_picker`, validasi ukuran,
/// dan state loading.
class QuizImagePicker extends StatelessWidget {
  final Uint8List? bytes;
  final bool picking;
  final VoidCallback? onPick;
  final VoidCallback onRemove;

  const QuizImagePicker({
    super.key,
    required this.bytes,
    this.picking = false,
    required this.onPick,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: picking ? null : onPick,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: AppColors.divider,
            width: AppBorderWidth.regular,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: picking
            ? const Center(child: CircularProgressIndicator())
            : bytes == null
            ? const _Placeholder()
            : _Preview(bytes: bytes!, onRemove: onRemove),
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_photo_alternate_outlined,
          size: AppIconSize.lg,
          color: AppColors.textMuted,
        ),
        const SizedBox(height: AppSpacing.space6),
        Text(
          'Pilih Gambar (jpg, png, webp · maks 5 MB)',
          style: AppTextStyles.button.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final Uint8List bytes;
  final VoidCallback onRemove;

  const _Preview({required this.bytes, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(bytes, fit: BoxFit.cover),
        Positioned(
          top: AppSpacing.space4,
          right: AppSpacing.space4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.space4),
              decoration: BoxDecoration(
                color: AppColors.textPrimary.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: AppIconSize.sm,
                color: AppColors.textOnPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
