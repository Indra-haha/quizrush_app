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

  List<String> _kategoriOptions = const [Quizes.defaultKategori];
  String? _selectedKategori;

  /// URL aset gambar hasil unggah Cloudinary (secure_url);
  /// dikirim sebagai `path` saat save.
  QuizImageAsset? _imageUpload;
  bool _uploading = false;
  bool _uploadFailed = false;
  String? _uploadLabel;

  /// Penanda urutan unggah supaya hasil upload gambar lama diabaikan.
  int _uploadSeq = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadKategoriOptions());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  /// Isi pilihan kategori dari kuis milik user. Form create quiz belum
  /// mengirim kategori ke API, jadi kegagalan di sini cukup memakai fallback.
  Future<void> _loadKategoriOptions() async {
    final token = await SessionService.instance.getToken();
    if (token == null) return;
    try {
      final options = await QuizService.instance.fetchKategoriOptions(
        token: token,
      );
      if (!mounted || options.isEmpty) return;
      setState(() => _kategoriOptions = options);
    } catch (_) {
      // Dropdown tetap memakai fallback "Umum".
    }
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

  /// Minta AI membuatkan soal dari [topic], lalu ganti seluruh daftar
  /// pertanyaan di form dengan hasilnya. Balas `true` bila berhasil.
  Future<bool> _suggest(String topic) async {
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
    } catch (_) {
      if (!mounted) return false;
      AppSnackBar.error(
        context,
        'Tidak dapat terhubung ke server. Periksa koneksi lalu coba lagi.',
      );
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
        path: _imageUpload!.path,
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
      backgroundColor: AppColors.pageBase,
      appBar: AppHeaderBarWithActions(
        title: 'Buat Quiz',
        titleStyle: CreateQuizTextStyles.headerTitle,
        backgroundColor: CreateQuizPageStyles.headerBackground,
        elevation: CreateQuizPageStyles.headerElevation,
        shadowColor: CreateQuizPageStyles.headerShadowColor,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [_buildSaveButton()],
      ),
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: CreateQuizPageStyles.pagePadding,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: CreateQuizPageStyles.contentMaxWidth,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLabel('Judul Quiz'),
                  const SizedBox(height: AppSpacing.space4),
                  _buildTitleField(),
                  const SizedBox(height: AppSpacing.space10),
                  _buildDescriptionHeader(),
                  const SizedBox(height: AppSpacing.space4),
                  _buildDescriptionField(),
                  const SizedBox(height: AppSpacing.space10),
                  Center(child: _buildSuggestButton()),
                  const SizedBox(height: AppSpacing.space10),
                  _buildLabel('Cover Quiz'),
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
                  const SizedBox(height: AppSpacing.space12),
                  for (var i = 0; i < _questions.length; i++) ...[
                    _buildQuestionEditor(i),
                    if (i < _questions.length - 1)
                      const SizedBox(height: AppSpacing.space12),
                  ],
                  const SizedBox(height: AppSpacing.space12),
                  _buildAddQuestionButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final enabled = !_saving && !_uploading;

    return Opacity(
      opacity: enabled ? 1 : CreateQuizPageStyles.saveDisabledOpacity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? _save : null,
          customBorder: CreateQuizPageStyles.saveButtonShape,
          child: Ink(
            decoration: CreateQuizPageStyles.saveButtonDecoration,
            child: Padding(
              padding: CreateQuizPageStyles.saveButtonPadding,
              child: _saving
                  ? const SizedBox(
                      width: CreateQuizPageStyles.saveProgressSize,
                      height: CreateQuizPageStyles.saveProgressSize,
                      child: CircularProgressIndicator(
                        strokeWidth: CreateQuizPageStyles.saveProgressStroke,
                        color: AppColors.textOnPrimary,
                      ),
                    )
                  : Text('Simpan', style: CreateQuizTextStyles.saveAction),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: CreateQuizTextStyles.fieldLabel);
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: CreateQuizTextStyles.fieldValue,
      decoration: CreateQuizPageStyles.fieldDecoration(
        hint: 'Masukkan judul yang menarik...',
      ),
    );
  }

  Widget _buildDescriptionHeader() {
    return Row(
      children: [
        Expanded(child: _buildLabel('Deskripsi Quiz')),
        const SizedBox(width: AppSpacing.space4),
        _buildKategoriButton(),
      ],
    );
  }

  Widget _buildKategoriButton() {
    final label = _selectedKategori ?? 'Kategori Quiz';

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: CreateQuizPageStyles.categoryMaxWidth,
      ),
      child: PopupMenuButton<String>(
        tooltip: 'Pilih kategori',
        onSelected: (value) => setState(() => _selectedKategori = value),
        itemBuilder: (_) => [
          for (final option in _kategoriOptions)
            PopupMenuItem<String>(value: option, child: Text(option)),
        ],
        child: Container(
          padding: CreateQuizPageStyles.categoryPadding,
          decoration: CreateQuizPageStyles.categoryDecoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CreateQuizTextStyles.category,
                ),
              ),
              const SizedBox(width: CreateQuizPageStyles.categoryGap),
              const Icon(
                Icons.keyboard_arrow_down,
                size: CreateQuizPageStyles.categoryIconSize,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      maxLines: null,
      minLines: 2,
      style: CreateQuizTextStyles.fieldValue,
      decoration: CreateQuizPageStyles.fieldDecoration(
        hint: 'Masukkan Keterangan',
      ),
    );
  }

  Widget _buildSuggestButton() {
    return FilledButton(
      onPressed: _openSuggestSheet,
      style: CreateQuizPageStyles.suggestButton,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: CreateQuizPageStyles.suggestIconSize,
          ),
          const SizedBox(width: CreateQuizPageStyles.suggestGap),
          Text('Generate Soal', style: CreateQuizTextStyles.suggest),
        ],
      ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _addQuestion,
        borderRadius: AppRadius.xxl,
        child: Container(
          width: double.infinity,
          padding: CreateQuizPageStyles.addQuestionPadding,
          decoration: CreateQuizPageStyles.addQuestionDecoration,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: CreateQuizPageStyles.addQuestionCircleSize,
                height: CreateQuizPageStyles.addQuestionCircleSize,
                decoration: CreateQuizPageStyles.addQuestionCircleDecoration,
                child: const Icon(
                  Icons.add,
                  size: CreateQuizPageStyles.addQuestionIconSize,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: CreateQuizPageStyles.addQuestionGap),
              Text(
                'Tambah Pertanyaan',
                textAlign: TextAlign.center,
                style: CreateQuizTextStyles.addQuestion,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sheet input topik untuk saran AI. Tombol "Buat Soal" memanggil
/// [onSubmit] dengan topik yang dimasukkan; bila sukses sheet ditutup dan
/// editor pertanyaan di halaman utama sudah terisi hasil AI.
class _SuggestSheet extends StatefulWidget {
  const _SuggestSheet({required this.onSubmit});

  final Future<bool> Function(String topic) onSubmit;

  @override
  State<_SuggestSheet> createState() => _SuggestSheetState();
}

class _SuggestSheetState extends State<_SuggestSheet> {
  final _controller = TextEditingController();
  bool _loading = false;

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
    final success = await widget.onSubmit(topic);
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
            'pertanyaan di form. Jumlah soal menyesuaikan topik.',
            style: CreateQuizTextStyles.suggestSheetBody,
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
