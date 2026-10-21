import 'dart:math';

import 'package:flutter/material.dart';

import '../../helpers/pin.dart';
import '../../helpers/room_launcher.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_inline_error.dart';
import '../../widgets/join_button.dart';
import '../../widgets/join_game_header.dart';
import '../../widgets/join_game_hero.dart';
import '../../widgets/join_name_field.dart';
import '../../widgets/pin_input_field.dart';

/// Halaman input PIN room: memverifikasi 6 digit PIN lewat
/// `POST /api/rooms/verify` (API.md §5.3) lalu, kalau valid, mengganti halaman
/// ini dengan ruang tunggu yang membuka WebSocket
/// `GET /api/rooms?token=<JWT room>` (API.md §9.1).
///
/// Nama panggilan yang diinput pengguna dikirim sebagai nickname WebSocket
/// (`name` pada API.md §9.1). Bila dikosongkan, ruang tunggu memakai nama
/// tampilan dari sesi login.
class EnterPinPage extends StatefulWidget {
  const EnterPinPage({super.key});

  @override
  State<EnterPinPage> createState() => _EnterPinPageState();
}

class _EnterPinPageState extends State<EnterPinPage> {
  /// Nama panggilan acak yang bisa dipilih lewat ikon pada field isian.
  static const _nicknames = <String>[
    'Sang Juara',
    'Bintang Kala',
    'Kilat Besi',
    'Garuda Emas',
    'Rajawali',
    'Petualang',
    'Badai Bokar',
    'Panda Putih',
  ];

  final _pinController = TextEditingController();
  final _nameController = TextEditingController();
  final _random = Random();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// Nama panggilan yang dikirim ke server; `null` bila dikosongkan.
  String? get _nickname {
    final name = _nameController.text.trim();
    return name.isEmpty ? null : name;
  }

  void _randomizeNickname() {
    final picked = _nicknames[_random.nextInt(_nicknames.length)];
    _nameController.value = TextEditingValue(
      text: picked,
      selection: TextSelection.collapsed(offset: picked.length),
    );
    setState(() {});
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
      await RoomLauncher.enter(
        context: context,
        pin: pin,
        replace: true,
        nickname: _nickname,
      );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.space12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              JoinGameHeader(onBack: () => Navigator.of(context).pop()),
              const SizedBox(height: AppSpacing.space8),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 448),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space9,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const JoinGameHero(),
                        const SizedBox(height: AppSpacing.space8),
                        _FormCard(
                          pinController: _pinController,
                          nameController: _nameController,
                          submitting: _submitting,
                          error: _error,
                          onPinChanged: () {
                            if (_error != null) setState(() => _error = null);
                          },
                          onRandomize: _randomizeNickname,
                          onSubmit: _submit,
                        ),
                        const SizedBox(height: AppSpacing.space6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu isian PIN + nama panggilan + tombol gabung.
class _FormCard extends StatelessWidget {
  final TextEditingController pinController;
  final TextEditingController nameController;
  final bool submitting;
  final String? error;
  final VoidCallback onPinChanged;
  final VoidCallback onRandomize;
  final VoidCallback onSubmit;

  const _FormCard({
    required this.pinController,
    required this.nameController,
    required this.submitting,
    required this.error,
    required this.onPinChanged,
    required this.onRandomize,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space10),
      decoration: ShapeDecoration(
        color: AppColors.textOnPrimary.withValues(alpha: 0.95),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: AppBorderWidth.hairline,
            color: AppColors.primaryBorder.withValues(alpha: 0.3),
          ),
          borderRadius: AppRadius.xxl,
        ),
        shadows: AppShadows.joinCard,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PIN PERMAINAN', style: AppTextStyles.accentLabel),
          const SizedBox(height: AppSpacing.space6),
          PinInputField(
            controller: pinController,
            enabled: !submitting,
            onSubmitted: (_) => onSubmit(),
            onChanged: (_) => onPinChanged(),
          ),
          if (error != null) ...[
            const SizedBox(height: AppSpacing.space4),
            AppInlineError(message: error!),
          ],
          const SizedBox(height: AppSpacing.space10),
          JoinButton(
            label: 'GABUNG',
            loading: submitting,
            loadingLabel: 'Memverifikasi PIN...',
            onPressed: onSubmit,
          ),
        ],
      ),
    );
  }
}
