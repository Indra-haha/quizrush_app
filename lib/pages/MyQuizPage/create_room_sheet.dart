import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/quiz.dart';
import '../../models/room.dart';
import '../../services/api_client.dart';
import '../../services/room_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_field_decoration.dart';
import '../../widgets/app_inline_error.dart';
import '../../widgets/app_primary_button.dart';

Future<Room?> showCreateRoomSheet(
  BuildContext context,
  List<Quizes> quarantine,
) {
  return showModalBottomSheet<Room>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.textPrimary.withValues(alpha: 0.35),
    builder: (context) => AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: CreateRoomSheet(quarantine: quarantine),
      ),
    ),
  );
}

class CreateRoomSheet extends StatefulWidget {
  final List<Quizes> quarantine;

  const CreateRoomSheet({super.key, required this.quarantine});

  @override
  State<CreateRoomSheet> createState() => _CreateRoomSheetState();
}

class _CreateRoomSheetState extends State<CreateRoomSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedQuizId;
  bool _submitting = false;
  String? _error;

  List<Quizes> get _quarantine => widget.quarantine;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onQuizChanged(String? id) {
    setState(() => _selectedQuizId = id);
  }

  bool get _canSubmit =>
      _selectedQuizId != null &&
      _titleController.text.trim().isNotEmpty &&
      !_submitting;

  Future<void> _submit() async {
    final quizId = _selectedQuizId;
    if (quizId == null || !_canSubmit) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final token = await SessionService.instance.getToken();
      if (token == null) {
        throw ApiException('Sesi tidak valid.', statusCode: 401);
      }
      final room = await RoomService.instance.createRoom(
        token: token,
        quizId: quizId,
        judul: _titleController.text.trim(),
        isi: _descriptionController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(room);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
    } catch (e) {
      debugPrint('Create room error: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server.';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space9,
        AppSpacing.space6,
        AppSpacing.space9,
        AppSpacing.space9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Text('Create Room', style: AppTextStyles.heading1),
            const SizedBox(height: AppSpacing.space8),
            DropdownButtonFormField<String>(
              initialValue: _selectedQuizId,
              isExpanded: true,
              isDense: true,
              menuMaxHeight: MediaQuery.sizeOf(context).height * 0.4,
              decoration: _inputDecoration('Pilih Kuis'),
              hint: Text(
                _quarantine.isEmpty
                    ? 'Tidak ada kuis tanpa room'
                    : 'Pilih kuis...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                for (final quiz in _quarantine)
                  DropdownMenuItem(
                    value: quiz.id,
                    child: Text(
                      quiz.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: _submitting ? null : _onQuizChanged,
            ),
            const SizedBox(height: AppSpacing.space6),
            TextField(
              controller: _titleController,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.words,
              scrollPadding: const EdgeInsets.only(
                bottom: AppSpacing.scrollClearanceLarge,
              ),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('Judul'),
            ),
            const SizedBox(height: AppSpacing.space6),
            TextField(
              controller: _descriptionController,
              enabled: !_submitting,
              maxLines: 2,
              scrollPadding: const EdgeInsets.only(
                bottom: AppSpacing.scrollClearanceLarge,
              ),
              decoration: _inputDecoration('Deskripsi'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.space6),
              AppInlineError(message: _error!),
            ],
            const SizedBox(height: AppSpacing.space9),
            AppPrimaryButton(
              label: 'Kirim',
              onPressed: _canSubmit ? _submit : null,
              loading: _submitting,
              radius: 9999,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space9,
                vertical: AppSpacing.space15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return AppFieldDecoration.filled(label: label).build();
  }
}
