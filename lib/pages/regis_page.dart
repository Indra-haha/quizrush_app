import 'dart:async';

import 'package:flutter/material.dart';

import '../helpers/auth_validator.dart';
import '../helpers/format.dart';
import '../services/api/api_client.dart';
import '../services/api/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/auth_fields.dart';
import '../widgets/auth_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _sekolahController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _agreed = false;

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2005),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _tanggalLahirController.text =
            "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  Future<void> _register() async {
    if (_isLoading) return;
    final nama = _namaController.text.trim();
    final username = _usernameController.text.trim();
    final sekolah = _sekolahController.text.trim();
    final tanggalLahir = formatTanggalLahir(
      _tanggalLahirController.text.trim(),
    );
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final error = AuthValidator.register(
      nama: nama,
      username: username,
      sekolah: sekolah,
      tanggalLahir: tanggalLahir,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (error != null) {
      AppSnackBar.error(context, error);
      return;
    }
    if (!_agreed) {
      AppSnackBar.error(
        context,
        'Kamu harus menyetujui Syarat & Ketentuan serta Kebijakan Privasi',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.register(
        nama: nama,
        username: username,
        sekolah: sekolah,
        tanggalLahir: tanggalLahir,
        password: password,
      );
      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Registrasi berhasil, a/n ${user.nama} (${user.username})',
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        Navigator.pop(context);
      });
    } on TimeoutException {
      AppSnackBar.error(
        context,
        "Server tidak merespons. Pastikan backend berjalan.",
      );
    } on ApiException catch (e) {
      AppSnackBar.error(context, e.message);
    } catch (_) {
      AppSnackBar.error(context, "Tidak dapat terhubung ke server.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _sekolahController.dispose();
    _tanggalLahirController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthPageScaffold(
      cardChildren: [
        const AuthBrandHeader(),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: AppSpacing.space8,
          children: [
            AuthField(
              controller: _namaController,
              label: 'Nama Lengkap',
              hint: 'Contoh: Budi Santoso',
              icon: Icons.person,
            ),
            AuthField(
              controller: _usernameController,
              label: 'Username',
              hint: 'Contoh: Budi Santoso',
              icon: Icons.alternate_email,
            ),
            AuthField(
              controller: _sekolahController,
              label: 'Sekolah',
              hint: 'Contoh: SMAN 1 Jakarta / Pemrograman Mobile',
              icon: Icons.school,
              iconSize: AppIconSize.xl,
              iconOffset: AppSpacing.space15,
              iconGap: AppSpacing.space4,
              boxPadding: const EdgeInsets.only(
                top: AppSpacing.space15,
                right: AppSpacing.space8,
                bottom: AppSpacing.space8,
              ),
            ),
            AuthField(
              controller: _tanggalLahirController,
              label: 'Tanggal Lahir',
              hint: 'dd/mm/yyyy',
              icon: Icons.calendar_month,
              readOnly: true,
              onTap: _pickDate,
            ),
            AuthField(
              controller: _passwordController,
              label: 'Kata Sandi',
              hint: 'Minimal 8 karakter',
              icon: Icons.lock,
              obscureText: true,
            ),
            AuthField(
              controller: _confirmPasswordController,
              label: 'Konfirmasi Kata Sandi',
              hint: 'Minimal 8 karakter',
              icon: Icons.lock_reset,
              obscureText: true,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: AuthTermsRow(
            value: _agreed,
            onChanged: (value) => setState(() => _agreed = value),
          ),
        ),
        AuthSubmitButton(
          label: 'Daftar',
          loading: _isLoading,
          onPressed: _register,
          gradient: true,
        ),
        AuthPageFooter(
          text: 'Sudah punya akun? ',
          linkText: 'Masuk di sini',
          onLinkTap: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
