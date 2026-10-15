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
import '../../widgets/app_field_decoration.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_secondary_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/quiz_image_picker.dart';
import '../../widgets/quiz_question_editor.dart';

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
                QuizImagePicker(
                  bytes: _imageBytes,
                  picking: _pickingImage,
                  onPick: _pickImage,
                  onRemove: _removeImage,
                ),
                const SizedBox(height: AppSpacing.space10),
                for (var i = 0; i < _questions.length; i++) ...[
                  _buildQuestionEditor(i),
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

  Widget _buildQuestionEditor(int index) {
    final question = _questions[index];

    return QuizQuestionEditor(
      index: index,
      questionController: question.question,
      optionControllers: question.options,
      skorController: question.skor,
      correctIdx: question.correctIdx,
      duration: question.duration,
      onCorrectChanged: (value) => setState(() => question.correctIdx = value),
      onDurationChanged: (value) => setState(() => question.duration = value),
      onRemove: _questions.length == 1 ? null : () => _removeQuestion(index),
    );
  }

  Widget _buildAddQuestionButton() {
    return AppSecondaryButton(
      label: 'Tambah Pertanyaan',
      icon: Icons.add,
      onPressed: _addQuestion,
    );
  }
}
