import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/quiz.dart';
import '../../models/room.dart';
import '../../services/api_client.dart';
import '../../services/room_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';

Future<Room?> showCreateRoomSheet(BuildContext context, List<Quizes> quarantine) {
  return showModalBottomSheet<Room>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.35),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                  color: AppColors.neutralBorder,
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Create Room', style: AppTextStyles.heading1),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedQuizId,
              isExpanded: true,
              isDense: true,
              menuMaxHeight: MediaQuery.sizeOf(context).height * 0.4,
              decoration: _inputDecoration('Pilih Kuis'),
              hint: Text(
                _quarantine.isEmpty ? 'Tidak ada kuis tanpa room' : 'Pilih kuis...',
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
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              enabled: !_submitting,
              textCapitalization: TextCapitalization.words,
              scrollPadding: const EdgeInsets.only(bottom: 160),
              onChanged: (_) => setState(() {}),
              decoration: _inputDecoration('Judul'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              enabled: !_submitting,
              maxLines: 2,
              scrollPadding: const EdgeInsets.only(bottom: 160),
              decoration: _inputDecoration('Deskripsi'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _canSubmit ? _submit : null,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Kirim',
                        style: GoogleFonts.montserrat(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.lineLight,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: AppColors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}