import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/api/api_client.dart';
import '../../services/api/feedback_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/app_snackbar.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _usernameController = TextEditingController();
  final _kesanController = TextEditingController();
  final _saranController = TextEditingController();

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPrefilledUsername());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _kesanController.dispose();
    _saranController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefilledUsername() async {
    final user = await SessionService.instance.getUser();
    final username = (user?['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty && mounted) {
      if (_usernameController.text.trim().isEmpty) {
        setState(() {
          _usernameController.text = username;
        });
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(text, style: CreateQuizTextStyles.fieldLabel);
  }


  /// Field multi-baris mengikuti gaya field deskripsi di CreateQuizPage.
  Widget _buildKesanField() {
    return TextField(
      controller: _kesanController,
      maxLines: null,
      minLines: 3,
      style: CreateQuizTextStyles.fieldValue,
      textInputAction: TextInputAction.newline,
      decoration: CreateQuizPageStyles.fieldDecoration(
        hint: 'Masukkan kesan Anda tentang aplikasi...',
      ),
    );
  }

  /// Field multi-baris mengikuti gaya field deskripsi di CreateQuizPage.
  Widget _buildSaranField() {
    return TextField(
      controller: _saranController,
      maxLines: null,
      minLines: 3,
      style: CreateQuizTextStyles.fieldValue,
      textInputAction: TextInputAction.newline,
      decoration: CreateQuizPageStyles.fieldDecoration(
        hint: 'Masukkan saran untuk perbaikan atau fitur baru...',
      ),
    );
  }

  Future<void> _submitFeedback() async {
    final username = _usernameController.text.trim();
    final kesan = _kesanController.text.trim();
    final saran = _saranController.text.trim();

    if (username.isEmpty) {
      AppSnackBar.error(context, 'username wajib diisi');
      return;
    }
    if (kesan.isEmpty) {
      AppSnackBar.error(context, 'kesan wajib diisi');
      return;
    }
    if (saran.isEmpty) {
      AppSnackBar.error(context, 'saran wajib diisi');
      return;
    }

    setState(() => _submitting = true);

    try {
      final token = await SessionService.instance.getToken();
      final response = await FeedbackService.instance.sendFeedback(
        username: username,
        kesan: kesan,
        saran: saran,
        token: token,
      );

      if (!mounted) return;
      setState(() {
        _submitting = false;
        _kesanController.clear();
        _saranController.clear();
      });

      AppSnackBar.success(context, response.message);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      AppSnackBar.error(context, 'Gagal mengirim feedback: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBase,
      appBar: AppHeaderBarWithActions(
        title: 'Feedback',
        titleStyle: CreateQuizTextStyles.headerTitle,
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: _buildList(),
    );
  }

  Widget _buildList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(
        top: AppSpacing.space8,
        left: AppSpacing.space9,
        right: AppSpacing.space9,
        bottom: AppSpacing.fabClearance,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: CreateQuizPageStyles.contentMaxWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Kami sangat menghargai masukan Anda. Silakan kirimkan saran dan kesan Anda untuk membantu kami mengembangkan aplikasi menjadi lebih baik.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space10),
                _buildLabel('Kesan'),
                const SizedBox(height: AppSpacing.space4),
                _buildKesanField(),
                const SizedBox(height: AppSpacing.space10),
                _buildLabel('Saran'),
                const SizedBox(height: AppSpacing.space4),
                _buildSaranField(),
                const SizedBox(height: AppSpacing.space12),
                AppPrimaryButton(
                  label: 'Kirim Feedback',
                  loading: _submitting,
                  loadingLabel: 'Mengirim...',
                  icon: Icons.send_rounded,
                  onPressed: _submitting ? null : _submitFeedback,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
