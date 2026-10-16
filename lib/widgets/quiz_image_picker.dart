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

  /// True selama gambar diunggah ke Cloudinary; menampilkan overlay progres
  /// dengan [uploadLabel] sebagai teks tahap.
  final bool uploading;

  /// Teks tahap pada overlay progres (mis. "Minta signature ke server…").
  final String? uploadLabel;

  /// True bila unggah ke Cloudinary gagal; menampilkan overlay error.
  final bool uploadError;

  /// Dipanggil saat tombol "Coba lagi" pada overlay error ditekan.
  final VoidCallback? onRetry;

  const QuizImagePicker({
    super.key,
    required this.bytes,
    this.picking = false,
    required this.onPick,
    required this.onRemove,
    this.uploading = false,
    this.uploadLabel,
    this.uploadError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: picking || uploading ? null : onPick,
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
            : _Preview(
                bytes: bytes!,
                onRemove: onRemove,
                uploading: uploading,
                uploadLabel: uploadLabel,
                uploadError: uploadError,
                onRetry: onRetry,
              ),
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
  final bool uploading;
  final String? uploadLabel;
  final bool uploadError;
  final VoidCallback? onRetry;

  const _Preview({
    required this.bytes,
    required this.onRemove,
    required this.uploading,
    required this.uploadLabel,
    required this.uploadError,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.memory(bytes, fit: BoxFit.cover),
        if (uploading) _UploadingOverlay(label: uploadLabel),
        if (uploadError) _ErrorOverlay(onRetry: onRetry),
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

class _UploadingOverlay extends StatelessWidget {
  const _UploadingOverlay({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.55),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.space6),
            Text(
              label ?? 'Mengunggah gambar…',
              key: const ValueKey('quizImageUploadLabel'),
              style: AppTextStyles.button.copyWith(
                color: AppColors.textOnPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorOverlay extends StatelessWidget {
  const _ErrorOverlay({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.textPrimary.withValues(alpha: 0.7),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: AppIconSize.lg,
              color: AppColors.textOnPrimary,
            ),
            const SizedBox(height: AppSpacing.space5),
            Text(
              'Gagal mengunggah ke Cloudinary',
              style: AppTextStyles.button.copyWith(
                color: AppColors.textOnPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.space5),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: AppIconSize.body),
              label: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
