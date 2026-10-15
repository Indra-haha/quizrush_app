import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/quiz_form_validator.dart';
import '../../helpers/quiz_image.dart';
import '../../models/quiz.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/quiz_option_theme.dart';
import '../../widgets/app_field_decoration.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_secondary_button.dart';
import '../../widgets/app_snackbar.dart';

const _durations = [1.5, 2.0, 3.0, 5.0];

class _QuestionData {
  final TextEditingController question = TextEditingController();
  final List<TextEditingController> options = List.generate(
    4,
    (_) => TextEditingController(),
  );
  final TextEditingController skor = TextEditingController();
  int? correctIdx;
  double duration = 2;

  void dispose() {
    question.dispose();
    for (final option in options) {
      option.dispose();
    }
    skor.dispose();
  }
}

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_QuestionData> _questions = [_QuestionData()];
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (!QuizImage.isWithinSizeLimit(bytes.length)) {
        if (!mounted) return;
        AppSnackBar.error(context, 'Ukuran gambar maksimal 5 MB.');
        return;
      }
      if (!mounted) return;
      setState(() {
        _image = picked;
        _imageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Gagal memilih gambar. ($e)');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _image = null;
      _imageBytes = null;
    });
  }

  String _imageFilename(XFile image) =>
      QuizImage.filename(name: image.name, path: image.path);

  void _addQuestion() {
    setState(() => _questions.add(_QuestionData()));
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() => _questions.removeAt(index).dispose());
  }

  String? _validate() {
    final questions = _questions
        .map(
          (question) => QuizFormQuestion(
            question: question.question.text,
            options: question.options.map((o) => o.text).toList(),
            correctIdx: question.correctIdx,
            skor: question.skor.text,
          ),
        )
        .toList();

    return QuizFormValidator.validate(
      title: _titleController.text,
      description: _descriptionController.text,
      hasImage: _imageBytes != null,
      questions: questions,
    );
  }

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      AppSnackBar.error(context, error);
      return;
    }

    setState(() => _saving = true);

    final token = await SessionService.instance.getToken();
    if (token == null) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, 'Sesi login berakhir. Silakan login kembali.');
      return;
    }

    final questions = _questions
        .map(
          (question) => QuizQuestionInput(
            question: question.question.text.trim(),
            options: question.options.map((o) => o.text.trim()).toList(),
            correctIdx: question.correctIdx!,
            duration: question.duration,
            skor: int.parse(question.skor.text.trim()),
          ),
        )
        .toList();

    try {
      await QuizService.instance.createQuiz(
        token: token,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        questions: questions,
        imageBytes: _imageBytes!,
        imageFilename: _imageFilename(_image!),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, 'Tidak dapat terhubung ke server. ($e)');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppHeaderBarWithActions(
        title: 'Create Quiz',
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          AppPrimaryButton(
            label: 'Simpan Quiz',
            onPressed: _save,
            loading: _saving,
            radius: 9999,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space9,
              vertical: AppSpacing.space6,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.space9,
                AppSpacing.space10,
                AppSpacing.space9,
                AppSpacing.space13,
              ),
              children: [
                _buildLabel('Judul Quiz'),
                const SizedBox(height: AppSpacing.space4),
                _buildTitleField(),
                const SizedBox(height: AppSpacing.space9),
                _buildLabel('Deskripsi'),
                const SizedBox(height: AppSpacing.space4),
                _buildDescriptionField(),
                const SizedBox(height: AppSpacing.space9),
                _buildLabel('Gambar Quiz'),
                const SizedBox(height: AppSpacing.space4),
                _buildImagePicker(),
                const SizedBox(height: AppSpacing.space10),
                for (var i = 0; i < _questions.length; i++) ...[
                  _buildQuestionCard(i),
                  const SizedBox(height: AppSpacing.space9),
                ],
                _buildAddQuestionButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: AppTextStyles.labelStrong);
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: AppTextStyles.heading5,
      decoration: const AppFieldDecoration.bordered(
        hint: 'Masukkan judul yang menarik...',
        radius: 32,
      ).build(),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: null,
      minLines: 2,
      style: AppTextStyles.bodyLarge,
      decoration: const AppFieldDecoration.bordered(
        hint: 'Masukkan deskripsi yang menarik...',
      ).build(),
    );
  }

  Widget _buildImagePicker() {
    final bytes = _imageBytes;

    return GestureDetector(
      onTap: _pickingImage ? null : _pickImage,
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
        child: _pickingImage
            ? const Center(child: CircularProgressIndicator())
            : bytes == null
            ? Column(
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
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(bytes, fit: BoxFit.cover),
                  Positioned(
                    top: AppSpacing.space4,
                    right: AppSpacing.space4,
                    child: GestureDetector(
                      onTap: _removeImage,
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
              ),
      ),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];

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
          Row(
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
                onPressed: _questions.length == 1
                    ? null
                    : () => _removeQuestion(index),
                child: Text(
                  'Hapus',
                  style: AppTextStyles.labelStrong.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          TextField(
            controller: question.question,
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
            _buildAnswerField(question, i),
            if (i < optionThemes.length - 1)
              const SizedBox(height: AppSpacing.space6),
          ],
          const SizedBox(height: AppSpacing.space8),
          _buildDurationAndSkor(question),
        ],
      ),
    );
  }

  Widget _buildAnswerField(_QuestionData question, int index) {
    final style = optionThemes[index];
    final selected = question.correctIdx == index;

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
              controller: question.options[index],
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
            onTap: () => setState(() => question.correctIdx = index),
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

  Widget _buildDurationAndSkor(_QuestionData question) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Durasi'),
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
                    value: question.duration,
                    isExpanded: true,
                    borderRadius: AppRadius.md,
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    items: [
                      for (final duration in _durations)
                        DropdownMenuItem(
                          value: duration,
                          child: Text(_durationLabel(duration)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => question.duration = value);
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
              _buildLabel('Poin (1-50)'),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                controller: question.skor,
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

  Widget _buildAddQuestionButton() {
    return AppSecondaryButton(
      label: 'Tambah Pertanyaan',
      icon: Icons.add,
      onPressed: _addQuestion,
    );
  }

  String _durationLabel(double duration) {
    final value = duration == duration.roundToDouble()
        ? duration.toInt()
        : duration;
    return '$value detik';
  }
}
