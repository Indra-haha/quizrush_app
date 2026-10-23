import 'package:flutter/material.dart';

import '../../helpers/pin.dart';
import '../../helpers/room_launcher.dart';
import '../../services/api/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_inline_error.dart';
import '../../widgets/app_primary_button.dart';
import '../../widgets/enter_pin_intro_card.dart';
import '../../widgets/pin_input_field.dart';

/// Halaman input PIN room: memverifikasi 6 digit PIN lewat
/// `POST /api/rooms/verify` (API.md §5.3) lalu, kalau valid, mengganti halaman
/// ini dengan ruang tunggu yang membuka WebSocket
/// `GET /api/rooms?token=<JWT room>` (API.md §9.1).
class EnterPinPage extends StatefulWidget {
  const EnterPinPage({super.key});

  @override
  State<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends State<EnterPinPage> {
  final _pinController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final pin = _pinController.text.trim();
    if (!Pin.isComplete(pin)) {
      setState(() => _error = 'PIN harus 6 digit angka.');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await RoomLauncher.enter(context: context, pin: pin, replace: true);
      if (!mounted) return;
      setState(() => _submitting = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message.isNotEmpty ? e.message : 'PIN tidak valid.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = 'Tidak bisa terhubung ke server. Coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBar(
        title: 'Masukkan PIN',
        leading: IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space9,
            AppSpacing.space8,
            AppSpacing.space9,
            AppSpacing.space10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const EnterPinIntroCard(),
              const SizedBox(height: AppSpacing.space10),
              PinInputField(
                controller: _pinController,
                enabled: !_submitting,
                onSubmitted: (_) => _submit(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.space4),
                AppInlineError(message: _error!),
              ],
              const SizedBox(height: AppSpacing.space10),
              AppPrimaryButton(
                label: 'Gabung Room',
                icon: Icons.login_rounded,
                loading: _submitting,
                loadingLabel: 'Memverifikasi PIN...',
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
