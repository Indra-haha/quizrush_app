import 'dart:async';

import 'package:flutter/material.dart';

import '../helpers/auth_validator.dart';
import '../helpers/password_hasher.dart';
import '../services/active_room_service.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_page.dart';
import 'button.dart';
import 'regis_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  // Jika masih ada session tersimpan yang valid, langsung masuk ke menu utama.
  Future<void> _restoreSession() async {
    final token = await SessionService.instance.getToken();
    if (token == null || !mounted) return;

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.checkSession(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(user: user)),
      );
    } catch (_) {
      await SessionService.instance.clear();
      ActiveRoomService.instance.clear();
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;
    final String username = _usernameController.text.trim();
    final String password = _passwordController.text;

    final error = AuthValidator.login(username: username, password: password);
    if (error != null) {
      AppSnackBar.error(context, error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.login(
        username: username,
        password: password,
      );
      await SessionService.instance.saveSession(result.token, result.user);
      if (_biometricEnabled) {
        await BiometricService.instance.updateCredentials(
          username: username,
          passwordHash: hashPassword(password),
          user: result.user,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(user: result.user)),
      );
    } on TimeoutException {
      AppSnackBar.error(
        context,
        'Server tidak merespons. Pastikan backend berjalan.',
      );
    } on ApiException catch (e) {
      AppSnackBar.error(context, e.message);
    } catch (_) {
      AppSnackBar.error(context, 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithBiometric() async {
    if (_isLoading) return;

    if (!_biometricEnabled) {
      AppSnackBar.error(
        context,
        'Sidik jari belum terdaftar. Aktifkan dulu di halaman Profile.',
      );
      return;
    }

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

    setState(() => _isLoading = true);
    try {
      final ok = await biometric.authenticate(reason: 'Login dengan sidik jari');
      if (!mounted) return;
      if (!ok) {
        AppSnackBar.error(context, 'Sidik jari tidak cocok. Coba lagi.');
        return;
      }

      final credentials = await biometric.readCredentials();
      if (credentials == null) {
        await biometric.disable();
        if (!mounted) return;
        AppSnackBar.error(
          context,
          'Data sidik jari tidak ditemukan. Aktifkan ulang di Profile.',
        );
        return;
      }

      // Sesi lama sudah dihancurkan saat logout, jadi minta sesi baru ke server
      // memakai kredensial tersimpan (sama seperti login manual).
      final result = await AuthService.instance.loginWithHash(
        username: credentials.username,
        passwordHash: credentials.passwordHash,
      );
      await SessionService.instance.saveSession(result.token, result.user);
      await biometric.updateCredentials(
        username: credentials.username,
        passwordHash: credentials.passwordHash,
        user: result.user,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(user: result.user)),
      );
    } on TimeoutException {
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Server tidak merespons. Pastikan backend berjalan.',
      );
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        await BiometricService.instance.disable();
        if (!mounted) return;
        AppSnackBar.error(
          context,
          'Sidik jari tidak valid lagi. Silakan login manual.',
        );
      } else {
        if (!mounted) return;
        AppSnackBar.error(context, e.message);
      }
    } catch (_) {
      if (!mounted) return;
      AppSnackBar.error(context, 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      cardChildren: [
        const AuthFormTitle(title: 'Login'),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.space8,
          children: [
            AuthField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Contoh: Budi Santoso',
              icon: Icons.alternate_email,
              enabled: !_isLoading,
            ),
            AuthField(
              controller: _passwordController,
              label: 'Kata Sandi',
              hint: 'Minimal 8 karakter',
              icon: Icons.lock,
              obscureText: true,
              enabled: !_isLoading,
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: AuthSubmitButton(
                label: 'Masuk',
                loading: _isLoading,
                onPressed: _login,
                gradient: true,
              ),
            ),
            const SizedBox(width: AppSpacing.space4),
            Material(
              color: AppColors.primary,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: _isLoading ? null : _loginWithBiometric,
                customBorder: const CircleBorder(),
                child: Container(
                  width: AppSizes.authBiometric,
                  height: AppSizes.authBiometric,
                  alignment: Alignment.center,
                  child: Tooltip(
                    message: _biometricEnabled
                        ? 'Login dengan sidik jari'
                        : 'Aktifkan sidik jari di Profile',
                    child: Icon(
                      Icons.fingerprint,
                      size: AppIconSize.lg,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        AuthPageFooter(
          text: 'Belum punya akun? ',
          linkText: 'Buat di sini',
          onLinkTap: _isLoading
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
        ),
      ],
    );
  }
}
