import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import 'button.dart';
import 'regis_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreSession();
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
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;
    final String nim = _nimController.text.trim();
    final String password = _passwordController.text;

    if (nim.isEmpty || password.isEmpty) {
      AppSnackBar.error(context, 'NIM dan password wajib diisi');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.login(
        nim: nim,
        password: password,
      );
      await SessionService.instance.saveSession(result.token, result.user);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShell(user: result.user)),
      );
    } on TimeoutException {
      AppSnackBar.error(context, 'Server tidak merespons. Pastikan backend berjalan.');
    } on ApiException catch (e) {
      AppSnackBar.error(context, e.message);
    } catch (_) {
      AppSnackBar.error(context, 'Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'lib/assets/icon/logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Everything about Numbers',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppTextField(
                      controller: _nimController,
                      label: 'NIM',
                      icon: Icons.person_outline,
                      enabled: !_isLoading,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      enabled: !_isLoading,
                      onSubmitted: (_) => _login(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: AppLoadingIndicator(),
                            )
                          : const Text('Login'),
                    ),
                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterPage(),
                          ),
                        );
                      },
                      child: const Text(
                        'Belum punya akun? Registrasi',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
