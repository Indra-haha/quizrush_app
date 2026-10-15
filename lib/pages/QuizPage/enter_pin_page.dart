import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../helpers/pin.dart';
import '../../helpers/room_launcher.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar.dart';
import '../../widgets/app_inline_error.dart';
import '../../widgets/app_primary_button.dart';

/// Halaman input PIN room: memverifikasi 6 digit PIN lewat
/// `POST /api/rooms/verify` (API.md §5.3) lalu, kalau valid, mengganti halaman
/// ini dengan ruang tunggu yang membuka WebSocket
/// `GET /api/rooms?token=<JWT room>` (API.md §8.1).
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
              _introCard(),
              const SizedBox(height: AppSpacing.space10),
              _pinField(),
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

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space9),
      decoration: BoxDecoration(
        gradient: AppGradients.solidHero,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.brandGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.textOnPrimary.withValues(alpha: 0.16),
              borderRadius: AppRadius.md,
            ),
            child: const Icon(
              Icons.pin_outlined,
              color: AppColors.textOnPrimary,
              size: AppIconSize.lg,
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'Gabung ke Room',
            style: AppTextStyles.heading2.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            'Masukkan 6 digit PIN room untuk memverifikasi lalu '
            'masuk ke ruang tunggu kuis.',
            style: AppTextStyles.bodyMediumOnPrimary.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pinField() {
    return TextField(
      controller: _pinController,
      autofocus: true,
      enabled: !_submitting,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _submit(),
      onChanged: (_) {
        if (_error != null) setState(() => _error = null);
      },
      maxLength: 6,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(6),
      ],
      textAlign: TextAlign.center,
      style: AppTextStyles.code.copyWith(
        color: AppColors.primary,
        letterSpacing: 8,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '000000',
        hintStyle: AppTextStyles.code.copyWith(color: AppColors.info),
        filled: true,
        fillColor: AppColors.textOnPrimary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space8,
          vertical: AppSpacing.space9,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.lg,
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: AppBorderWidth.regular,
          ),
        ),
      ),
    );
  }
}
