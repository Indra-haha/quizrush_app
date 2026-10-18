import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../helpers/password_hasher.dart';
import '../services/active_room_service.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/quiz_cache_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_bar_with_actions.dart';
import '../widgets/app_primary_button.dart';
import '../widgets/points_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_fields.dart';
import 'login_redirect.dart';

/// Halaman profil pengguna: menampilkan data akun dan menyediakan logout.
class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;

  const ProfilePage({super.key, this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  bool _loggingOut = false;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_biometricBusy) return;
    setState(() => _biometricBusy = true);
    try {
      if (value) {
        await _enableBiometric();
      } else {
        await BiometricService.instance.disable();
        if (!mounted) return;
        setState(() => _biometricEnabled = false);
        AppSnackBar.show(context, 'Login sidik jari dinonaktifkan.');
      }
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _enableBiometric() async {
    final biometric = BiometricService.instance;

    if (!await biometric.isDeviceSupported()) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Perangkat tidak mendukung biometrik.');
      return;
    }
    if (!await biometric.hasEnrolledBiometrics()) {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Sidik jari belum terdaftar di perangkat. Daftarkan di Pengaturan.',
      );
      return;
    }

    final ok = await biometric.authenticate(reason: 'Aktifkan login sidik jari');
    if (!mounted) return;
    if (!ok) {
      AppSnackBar.error(context, 'Gagal verifikasi sidik jari.');
      return;
    }

    final user = await SessionService.instance.getUser();
    final username = (user?['username'] as String?)?.trim();
    if (user == null || username == null || username.isEmpty) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Sesi tidak ditemukan. Login ulang dahulu.');
      return;
    }

    final password = await _askPassword();
    if (!mounted) return;
    if (password == null || password.isEmpty) {
      AppSnackBar.error(
        context,
        'Password wajib diisi untuk mengaktifkan sidik jari.',
      );
      return;
    }

    await biometric.enable(
      BiometricCredentials(
        username: username,
        passwordHash: hashPassword(password),
        user: user,
      ),
    );
    if (!mounted) return;
    setState(() => _biometricEnabled = true);
    AppSnackBar.success(context, 'Login sidik jari diaktifkan.');
  }

  /// Meminta password untuk menyimpan kredensial login biometrik.
  Future<String?> _askPassword() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PasswordPromptDialog(),
    );
  }

  Future<void> _loadUser() async {
    final user = await SessionService.instance.getUser();
    if (user != null && mounted) {
      setState(() => _user = user);
    }
  }

  String get _nama => (_user?['nama'] as String?) ?? '';
  String get _username => (_user?['username'] as String?) ?? '';
  String get _kelas => (_user?['kelas'] as String?) ?? '';
  String get _tanggalLahir => (_user?['tanggal_lahir'] as String?) ?? '';

  String get _initials {
    final words = _nama.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    final letters = words.take(2).map((w) => w[0].toUpperCase()).join();
    return letters;
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);

    final token = await SessionService.instance.getToken();
    try {
      if (token != null) {
        await AuthService.instance.logout(token);
      }
    } catch (_) {
      // Backend tidak terjangkau; session lokal tetap dihapus.
    }
    await SessionService.instance.clear();
    await QuizCacheService.instance.clear();
    ActiveRoomService.instance.clear();
    if (!mounted) return;
    LoginRedirect.go(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderBarWithActions(
        title: 'Profile',
        actions: [PointsIndicator()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.space9),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary,
              child: Text(
                _initials,
                style: AppTextStyles.heading2Strong.copyWith(
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            _nama.isEmpty ? '-' : _nama,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading1Strong,
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(
            _username.isEmpty ? '-' : '@$_username',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space8),
              child: Column(
                children: [
                  _infoRow(Icons.badge_outlined, 'Nama', _nama),
                  const Divider(),
                  _infoRow(Icons.person_outline, 'Username', _username),
                  const Divider(),
                  _infoRow(Icons.school_outlined, 'Kelas', _kelas),
                  const Divider(),
                  _infoRow(
                    Icons.cake_outlined,
                    'Tanggal Lahir',
                    _tanggalLahir.isEmpty
                        ? '-'
                        : formatTanggalLahir(_tanggalLahir),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space10),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(
                    Icons.fingerprint,
                    color: AppColors.primary,
                    size: AppIconSize.lg,
                  ),
                  title: Text(
                    'Login dengan Sidik Jari',
                    style: AppTextStyles.labelStrong,
                  ),
                  subtitle: Text(
                    _biometricEnabled
                        ? 'Aktif — gunakan sidik jari untuk login'
                        : 'Daftarkan sidik jari / Face ID perangkat',
                    style: AppTextStyles.bodySmall,
                  ),
                  value: _biometricEnabled,
                  onChanged: _biometricBusy ? null : _toggleBiometric,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space10),
          AppPrimaryButton(
            label: 'Logout',
            icon: Icons.logout,
            loading: _loggingOut,
            loadingLabel: 'Keluar...',
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: AppIconSize.lg),
          const SizedBox(width: AppSpacing.space6),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          Text(
            value.isEmpty ? '-' : value,
            style: AppTextStyles.labelStrong.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog konfirmasi password untuk mengaktifkan login biometrik.
///
/// Mengelola [TextEditingController] miliknya sendiri agar controller tidak
/// di-dispose saat animasi keluar dialog masih berjalan (yang menyebabkan
/// error "TextEditingController was used after being disposed").
class _PasswordPromptDialog extends StatefulWidget {
  const _PasswordPromptDialog();

  @override
  State<_PasswordPromptDialog> createState() => _PasswordPromptDialogState();
}

class _PasswordPromptDialogState extends State<_PasswordPromptDialog> {
  final TextEditingController _controller = TextEditingController();

  void _submit() => Navigator.of(context).pop(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Konfirmasi Password'),
      content: PasswordField(
        controller: _controller,
        label: 'Password',
        icon: Icons.lock_outline,
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        TextButton(onPressed: _submit, child: const Text('Simpan')),
      ],
    );
  }
}
