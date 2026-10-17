import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../helpers/quiz_form_validator.dart';
import '../../helpers/quiz_image.dart';
import '../../models/quiz.dart';
import '../../services/ai_service.dart';
import '../../services/api_client.dart';
import '../../services/quiz_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_bottom_sheet.dart';
import '../../widgets/app_field_decoration.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_secondary_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/quiz_image_picker.dart';
import '../../widgets/quiz_question_editor.dart';
import '../../widgets/status_filter_chip.dart';

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

  /// Identitas aset gambar hasil unggah Cloudinary (public_id + format);
  /// dikirim sebagai `image_id`/`image_format` saat save.
  QuizImageAsset? _imageUpload;
  bool _uploading = false;
  bool _uploadFailed = false;
  String? _uploadLabel;

  /// Penanda urutan unggah supaya hasil upload gambar lama diabaikan.
  int _uploadSeq = 0;

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
        _imageUpload = null;
        _uploadFailed = false;
        _uploading = true;
        _uploadLabel = QuizImageUploadStage.requestingSignature.label;
      });
      unawaited(_uploadImage());
    } catch (e) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Gagal memilih gambar. ($e)');
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  /// Upload gambar terpilih ke Cloudinary: minta signature lalu unggah
  /// langsung (§4.2–§4.3). Hasilnya disimpan ke [_imageUpload].
  Future<void> _uploadImage() async {
    final image = _image;
    final bytes = _imageBytes;
    if (image == null || bytes == null) return;
    final seq = ++_uploadSeq;

    final token = await SessionService.instance.getToken();
    if (token == null) {
      if (!mounted || seq != _uploadSeq) return;
      setState(() {
        _uploading = false;
        _uploadFailed = true;
        _uploadLabel = null;
      });
      AppSnackBar.error(context, 'Sesi login berakhir. Silakan login kembali.');
      return;
    }

    try {
      final upload = await QuizService.instance.uploadQuizImage(
        token: token,
        imageBytes: bytes,
        imageFilename: _imageFilename(image),
        onStage: (stage) {
          if (!mounted || seq != _uploadSeq) return;
          setState(() => _uploadLabel = stage.label);
        },
      );
      if (!mounted || seq != _uploadSeq) return;
      setState(() {
        _imageUpload = upload;
        _uploading = false;
        _uploadFailed = false;
        _uploadLabel = null;
      });
    } on ApiException catch (e) {
      if (!mounted || seq != _uploadSeq) return;
      setState(() {
        _uploading = false;
        _uploadFailed = true;
        _uploadLabel = null;
      });
      AppSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted || seq != _uploadSeq) return;
      setState(() {
        _uploading = false;
        _uploadFailed = true;
        _uploadLabel = null;
      });
      AppSnackBar.error(context, 'Tidak dapat terhubung ke server. ($e)');
    }
  }

  void _retryUpload() {
    if (_uploading || _imageBytes == null) return;
    setState(() {
      _uploading = true;
      _uploadFailed = false;
      _uploadLabel = QuizImageUploadStage.requestingSignature.label;
    });
    unawaited(_uploadImage());
  }

  void _removeImage() {
    _uploadSeq++;
    setState(() {
      _image = null;
      _imageBytes = null;
      _imageUpload = null;
      _uploading = false;
      _uploadFailed = false;
      _uploadLabel = null;
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

  /// Minta AI membuatkan [count] soal dari [topic], lalu ganti seluruh daftar
  /// pertanyaan di form dengan hasilnya. Balas `true` bila berhasil.
  Future<bool> _suggest(String topic, int count) async {
    final token = await SessionService.instance.getToken();
    if (token == null) {
      if (!mounted) return false;
      AppSnackBar.error(context, 'Sesi login berakhir. Silakan login kembali.');
      return false;
    }

    try {
      final suggested = await AiService.instance.suggestQuestions(
        token: token,
        topic: topic,
        count: count,
      );
      if (!mounted) return false;
      if (suggested.isEmpty) {
        AppSnackBar.error(
          context,
          'AI tidak menghasilkan soal yang valid. Coba topik lain.',
        );
        return false;
      }
      setState(() {
        for (final question in _questions) {
          question.dispose();
        }
        _questions
          ..clear()
          ..addAll(suggested.map(_questionFrom));
      });
      AppSnackBar.success(
        context,
        'Berhasil membuat ${suggested.length} soal dari saran AI.',
      );
      return true;
    } on ApiException catch (e) {
      if (!mounted) return false;
      AppSnackBar.error(context, e.message);
      return false;
    } catch (e) {
      if (!mounted) return false;
      AppSnackBar.error(context, 'Tidak dapat terhubung ke server. ($e)');
      return false;
    }
  }

  /// Buka sheet input topik; hasil AI-nya mengisi editor pertanyaan.
  void _openSuggestSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SuggestSheet(onSubmit: _suggest),
    );
  }

  /// Bangun controller form soal dari hasil AI.
  _QuestionData _questionFrom(QuizQuestionInput input) {
    final question = _QuestionData();
    question.question.text = input.question;
    for (var i = 0; i < input.options.length; i++) {
      question.options[i].text = input.options[i];
    }
    question.correctIdx = input.correctIdx;
    question.duration = input.duration;
    question.skor.text = '${input.skor}';
    return question;
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
    if (_uploading) return;
    final error = _validate();
    if (error != null) {
      AppSnackBar.error(context, error);
      return;
    }
    if (_imageUpload == null) {
      AppSnackBar.error(
        context,
        'Gambar belum berhasil diunggah. Ketuk "Coba lagi" pada gambar.',
      );
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
        imageId: _imageUpload!.id,
        imageFormat: _imageUpload!.format,
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
            onPressed: _uploading ? null : _save,
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
                  uploading: _uploading,
                  uploadLabel: _uploadLabel,
                  uploadError: _uploadFailed,
                  onPick: _pickImage,
                  onRemove: _removeImage,
                  onRetry: _retryUpload,
                ),
                const SizedBox(height: AppSpacing.space9),
                _buildSuggestButton(),
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

  Widget _buildSuggestButton() {
    return AppSecondaryButton(
      label: 'Buat Soal dengan AI',
      icon: Icons.auto_awesome,
      onPressed: _openSuggestSheet,
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

/// Sheet input topik untuk saran AI. Tombol "Buat Soal" memanggil
/// [onSubmit] beserta jumlah soal yang dipilih; bila sukses sheet ditutup dan
/// editor pertanyaan di halaman utama sudah terisi hasil AI.
class _SuggestSheet extends StatefulWidget {
  const _SuggestSheet({required this.onSubmit});

  final Future<bool> Function(String topic, int count) onSubmit;

  @override
  State<_SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends State<_SuggestSheet> {
  /// Pilihan jumlah soal yang didukung server (maksimal 30).
  static const List<int> _countOptions = [5, 10, 20, 30];

  final _controller = TextEditingController();
  bool _loading = false;
  int _count = 5;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    final topic = _controller.text.trim();
    if (topic.isEmpty) {
      AppSnackBar.error(
        context,
        'Masukkan topik atau ide soal terlebih dahulu.',
      );
      return;
    }
    setState(() => _loading = true);
    final success = await widget.onSubmit(topic, _count);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: AppBottomSheet(
        title: 'Buat Soal dengan AI',
        children: [
          Text(
            'Masukkan topik/ide soal, hasilnya akan mengisi seluruh '
            'pertanyaan di form.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          TextField(
            controller: _controller,
            autofocus: true,
            enabled: !_loading,
            maxLines: null,
            minLines: 2,
            style: AppTextStyles.bodyLarge,
            decoration: const AppFieldDecoration.bordered(
              hint: 'mis. "Sejarah Majapahit" atau "Kecerdasan emosional"...',
            ).build(),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Jumlah soal',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              for (var i = 0; i < _countOptions.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.space4),
                StatusFilterChip(
                  label: '${_countOptions[i]}',
                  selected: _count == _countOptions[i],
                  onTap: _loading
                      ? () {}
                      : () => setState(() => _count = _countOptions[i]),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          AppPrimaryButton(
            label: 'Buat Soal',
            icon: Icons.auto_awesome,
            loading: _loading,
            loadingLabel: 'Membuat soal...',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
