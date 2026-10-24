import 'package:flutter/material.dart';
import '../widgets/app_options_select.dart' as list_options;
import '../theme/app_theme.dart';


/// Field untuk jawaban quiz dengan marker dan toggle jawaban benar.
/// Bisa dipakai di berbagai halaman.
class QuizAnswerField extends StatelessWidget {
  final int optionIndex;
  final TextEditingController controller;
  final int? correctIdx;
  final ValueChanged<int> onCorrectChanged;
  final String hintText;

  const QuizAnswerField({
    super.key,
    required this.optionIndex,
    required this.controller,
    required this.correctIdx,
    required this.onCorrectChanged,
    this.hintText = 'Tulis jawaban...',
  });

  @override
  Widget build(BuildContext context) {
    final color = CreateQuizQuestionStyles
        .answerColors[optionIndex % CreateQuizQuestionStyles.answerColors.length];
    final shape = CreateQuizQuestionStyles
        .answerShapes[optionIndex % CreateQuizQuestionStyles.answerShapes.length];
    final selected = correctIdx == optionIndex;

    return Container(
      width: double.infinity,
      padding: CreateQuizQuestionStyles.answerPadding,
      color: color,
      child: Row(
        children: [
          _AnswerMarker(shape: shape),
          const SizedBox(width: CreateQuizQuestionStyles.answerGap),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              style: CreateQuizTextStyles.answerInput,
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: CreateQuizTextStyles.answerHint,
                border: InputBorder.none,
                isDense: true,
                contentPadding: CreateQuizQuestionStyles.answerFieldPadding,
              ),
            ),
          ),
          const SizedBox(width: CreateQuizQuestionStyles.answerToggleGap),
          GestureDetector(
            onTap: () => onCorrectChanged(optionIndex),
            child: Container(
              width: CreateQuizQuestionStyles.toggleSize.width,
              height: CreateQuizQuestionStyles.toggleSize.height,
              alignment: Alignment.center,
              decoration: CreateQuizQuestionStyles.toggleDecoration(
                selected: selected,
              ),
              child: selected
                  ? Icon(
                      Icons.check,
                      size: CreateQuizShared.iconSmall,
                      color: color,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

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
      padding: CreateQuizShared.cardPadding,
      decoration: CreateQuizQuestionStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.space10),
          _buildQuestionField(),
          const SizedBox(height: AppSpacing.space10),
          for (var i = 0; i < optionControllers.length; i++) ...[
            QuizAnswerField(
              optionIndex: i,
              controller: optionControllers[i],
              correctIdx: correctIdx,
              onCorrectChanged: onCorrectChanged,
            ),
            if (i < optionControllers.length - 1)
              const SizedBox(height: AppSpacing.space5),
          ],
          const SizedBox(height: AppSpacing.space10),
          _buildDurationAndHadiah(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: CreateQuizShared.pillPadding,
          decoration: const ShapeDecoration(
            color: AppColors.quizAction,
            shape: CreateQuizShared.pillShape,
          ),
          child: Text(
            'Pertanyaan ${index + 1}',
            style: CreateQuizTextStyles.fieldLabelOnPrimary,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onRemove,
          style: CreateQuizQuestionStyles.deleteButton,
          child: Text('Hapus', style: CreateQuizTextStyles.deleteAction),
        ),
      ],
    );
  }

  Widget _buildQuestionField() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: CreateQuizQuestionStyles.questionMinHeight,
      ),
      child: Container(
        width: double.infinity,
        padding: CreateQuizQuestionStyles.questionPadding,
        child: TextField(
          controller: questionController,
          maxLines: null,
          minLines: 3,
          style: CreateQuizTextStyles.questionInput,
          decoration: InputDecoration(
            hintText: 'Tuliskan pertanyaan Anda di \nsini...',
            hintStyle: CreateQuizTextStyles.questionHint,
            border: InputBorder.none,
            isDense: true,
          ),
        ),
      ),
    );
  }

  Widget _buildDurationAndHadiah() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildDuration()),
        const SizedBox(width: CreateQuizShared.gapSmall),
        _buildHadiah(),
      ],
    );
  }

  Widget _buildDuration() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Durasi'),
        const SizedBox(height: CreateQuizShared.gapSmall),
        list_options.ListOptions<double>(
          optionLists: const [1.5, 2.0, 3.0, 5.0],
          selectedOption: duration,
          onSelectedChange: onDurationChanged,
        ),
      ],
    );
  }

  Widget _buildHadiah() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('Hadiah'),
            const SizedBox(width: CreateQuizShared.gapSmall),
            Text('Poin', style: CreateQuizTextStyles.pointsHint),
          ],
        ),
        const SizedBox(height: CreateQuizShared.gapSmall),
        SizedBox(
          width: CreateQuizQuestionStyles.pointsFieldWidth,
          child: TextField(
            controller: skorController,
            keyboardType: TextInputType.number,
            style: CreateQuizTextStyles.pointsInput,
            decoration: CreateQuizQuestionStyles.pointsDecoration(),
          ),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text, style: CreateQuizTextStyles.fieldLabel);
  }
}

class _AnswerMarker extends StatelessWidget {
  final CreateQuizAnswerShape shape;

  const _AnswerMarker({required this.shape});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CreateQuizQuestionStyles.answerMarkerBoxSize,
      height: CreateQuizQuestionStyles.answerMarkerBoxSize,
      child: Center(
        child: switch (shape) {
          CreateQuizAnswerShape.triangle => SizedBox.fromSize(
            size: CreateQuizQuestionStyles.answerMarkerTriangleSize,
            child: const CustomPaint(painter: _TriangleMarkerPainter()),
          ),
          CreateQuizAnswerShape.diamond => Transform.rotate(
            angle: CreateQuizQuestionStyles.answerMarkerDiamondRotation,
            child: const _BoxMarker(
              size: CreateQuizQuestionStyles.answerMarkerDiamondSize,
            ),
          ),
          CreateQuizAnswerShape.square => const _BoxMarker(
            size: CreateQuizQuestionStyles.answerMarkerSize,
          ),
          CreateQuizAnswerShape.circle => const _BoxMarker(
            size: CreateQuizQuestionStyles.answerMarkerSize,
            circular: true,
          ),
        },
      ),
    );
  }
}

class _BoxMarker extends StatelessWidget {
  final double size;
  final bool circular;

  const _BoxMarker({required this.size, this.circular = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: CreateQuizQuestionStyles.answerMarkerColor,
        shape: circular ? BoxShape.circle : BoxShape.rectangle,
        boxShadow: CreateQuizQuestionStyles.answerMarkerShadow,
      ),
    );
  }
}

class _TriangleMarkerPainter extends CustomPainter {
  const _TriangleMarkerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(
      path,
      CreateQuizQuestionStyles.answerMarkerShadowColor,
      CreateQuizQuestionStyles.answerMarkerShadowElevation,
      false,
    );
    canvas.drawPath(
      path,
      Paint()..color = CreateQuizQuestionStyles.answerMarkerColor,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
