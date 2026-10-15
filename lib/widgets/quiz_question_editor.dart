import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/quiz_option_theme.dart';
import 'app_field_decoration.dart';

const _durations = [1.5, 2.0, 3.0, 5.0];

/// Kartu editor satu pertanyaan quiz: judul, empat pilihan jawaban berwarna,
/// penanda jawaban benar, durasi, dan poin.
///
/// Murni presentational — seluruh [`TextEditingController`] dan state dimiliki
/// page, widget ini hanya merender dan meneruskan perubahan lewat callback.
class QuizQuestionEditor extends StatelessWidget {
  final int index;
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController skorController;
  final int? correctIdx;
  final double duration;
  final ValueChanged<int> onCorrectChanged;
  final ValueChanged<double> onDurationChanged;
  final VoidCallback? onRemove;

  const QuizQuestionEditor({
    super.key,
    required this.index,
    required this.questionController,
    required this.optionControllers,
    required this.skorController,
    required this.correctIdx,
    required this.duration,
    required this.onCorrectChanged,
    required this.onDurationChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space9),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: AppColors.textOnPrimary,
          width: AppBorderWidth.regular,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.space6),
          TextField(
            controller: questionController,
            maxLines: null,
            minLines: 3,
            style: AppTextStyles.buttonLarge.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: AppFieldDecoration.bordered(
              hint: 'Tuliskan pertanyaan Anda di sini...',
              hintStyle: AppTextStyles.hintLarge,
            ).build(),
          ),
          const SizedBox(height: AppSpacing.space8),
          for (var i = 0; i < optionThemes.length; i++) ...[
            _buildAnswerField(i),
            if (i < optionThemes.length - 1)
              const SizedBox(height: AppSpacing.space6),
          ],
          const SizedBox(height: AppSpacing.space8),
          _buildDurationAndSkor(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.md,
          ),
          child: Text(
            'Pertanyaan ${index + 1}',
            style: AppTextStyles.labelStrong.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onRemove,
          child: Text(
            'Hapus',
            style: AppTextStyles.labelStrong.copyWith(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerField(int option) {
    final style = optionThemes[option];
    final selected = correctIdx == option;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space6,
        vertical: AppSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: AppRadius.md,
        border: Border.all(color: style.border, width: AppBorderWidth.heavy),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.space6),
          Expanded(
            child: TextField(
              controller: optionControllers[option],
              style: AppTextStyles.button.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: style.hint,
                hintStyle: AppTextStyles.button.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.space7,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          GestureDetector(
            onTap: () => onCorrectChanged(option),
            child: Container(
              width: 44,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? style.dot : style.dot.withValues(alpha: 0.3),
                borderRadius: AppRadius.md,
              ),
              child: selected
                  ? const Icon(
                      Icons.check,
                      size: AppIconSize.sm,
                      color: AppColors.textOnPrimary,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationAndSkor() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Durasi'),
              const SizedBox(height: AppSpacing.space3),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.md,
                  border: Border.all(
                    color: AppColors.divider,
                    width: AppBorderWidth.regular,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: duration,
                    isExpanded: true,
                    borderRadius: AppRadius.md,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    items: [
                      for (final d in _durations)
                        DropdownMenuItem(
                          value: d,
                          child: Text(_durationLabel(d)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      onDurationChanged(value);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Poin (1-50)'),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                controller: skorController,
                keyboardType: TextInputType.number,
                style: AppTextStyles.button.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: AppFieldDecoration.bordered(
                  hint: '20',
                  hintStyle: AppTextStyles.hint,
                ).build(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text, style: AppTextStyles.labelStrong);
  }

  String _durationLabel(double value) {
    final shown = value == value.roundToDouble() ? value.toInt() : value;
    return '$shown detik';
  }
}
