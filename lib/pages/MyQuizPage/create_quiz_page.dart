import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    for (final question in _questions) {
      question.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionData()));
  }

  void _removeQuestion(int index) {
    if (_questions.length == 1) return;
    setState(() => _questions.removeAt(index).dispose());
  }

  String? _validate() {
    if (_titleController.text.trim().isEmpty) {
      return 'Judul quiz wajib diisi.';
    }
    if (_descriptionController.text.trim().isEmpty) {
      return 'Deskripsi quiz wajib diisi.';
    }
    for (var i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question.question.text.trim().isEmpty) {
        return 'Pertanyaan ${i + 1} wajib diisi.';
      }
      for (var j = 0; j < question.options.length; j++) {
        if (question.options[j].text.trim().isEmpty) {
          return 'Jawaban ${j + 1} pada pertanyaan ${i + 1} wajib diisi.';
        }
      }
      if (question.correctIdx == null) {
        return 'Pilih jawaban benar untuk pertanyaan ${i + 1}.';
      }
      final skor = int.tryParse(question.skor.text.trim());
      if (skor == null || skor < 1 || skor > 50) {
        return 'Poin pertanyaan ${i + 1} harus berupa angka 1-50.';
      }
    }
    return null;
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              children: [
                _buildLabel('Judul Quiz'),
                const SizedBox(height: 8),
                _buildTitleField(),
                const SizedBox(height: 20),
                _buildLabel('Deskripsi'),
                const SizedBox(height: 8),
                _buildDescriptionField(),
                const SizedBox(height: 24),
                for (var i = 0; i < _questions.length; i++) ...[
                  _buildQuestionCard(i),
                  const SizedBox(height: 20),
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
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      style: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.ink,
      ),
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
      style: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      decoration: const AppFieldDecoration.bordered(
        hint: 'Masukkan deskripsi yang menarik...',
      ).build(),
    );
  }

  Widget _buildQuestionCard(int index) {
    final question = _questions[index];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.heroBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.highlight,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  'Pertanyaan ${index + 1}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onHighlight,
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
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.dangerAction,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: question.question,
            maxLines: null,
            minLines: 3,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
            decoration: const AppFieldDecoration.bordered(
              hint: 'Tuliskan pertanyaan Anda di sini...',
              hintStyle: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.placeholderMuted,
              ),
            ).build(),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < optionThemes.length; i++) ...[
            _buildAnswerField(question, i),
            if (i < optionThemes.length - 1) const SizedBox(height: 12),
          ],
          const SizedBox(height: 16),
          _buildDurationAndSkor(question),
        ],
      ),
    );
  }

  Widget _buildAnswerField(_QuestionData question, int index) {
    final style = optionThemes[index];
    final selected = question.correctIdx == index;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: style.border, width: 4),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: style.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: question.options[index],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: style.hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => question.correctIdx = index),
            child: Container(
              width: 44,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? style.dot : style.dot.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: selected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
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
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.formFieldBg,
                  borderRadius: BorderRadius.circular(19),
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<double>(
                    value: question.duration,
                    isExpanded: true,
                    borderRadius: BorderRadius.circular(19),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
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
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Poin (1-50)'),
              const SizedBox(height: 6),
              TextField(
                controller: question.skor,
                keyboardType: TextInputType.number,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
                decoration: const AppFieldDecoration.bordered(
                  hint: '20',
                  hintStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.placeholder,
                  ),
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
