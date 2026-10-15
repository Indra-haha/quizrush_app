import 'dart:async';

import 'package:flutter/material.dart';
import '../helpers/auth_validator.dart';
import '../helpers/format.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_fields.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

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
    final kelas = _kelasController.text.trim();
    final tanggalLahir = formatTanggalLahir(
      _tanggalLahirController.text.trim(),
    );
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final error = AuthValidator.register(
      nama: nama,
      username: username,
      kelas: kelas,
      tanggalLahir: tanggalLahir,
      password: password,
      confirmPassword: confirmPassword,
    );
    if (error != null) {
      AppSnackBar.error(context, error);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.register(
        nama: nama,
        username: username,
        kelas: kelas,
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
    _kelasController.dispose();
    _tanggalLahirController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthFormCard(
      title: 'Registrasi Akun',
      children: [
        AppTextField(
          controller: _namaController,
          label: 'Nama Lengkap',
          icon: Icons.person,
        ),
        const SizedBox(height: AppSpacing.space8),
        AppTextField(
          controller: _usernameController,
          label: 'Username',
          icon: Icons.badge,
        ),
        const SizedBox(height: AppSpacing.space8),
        AppTextField(
          controller: _kelasController,
          label: 'Kelas',
          icon: Icons.class_,
        ),
        const SizedBox(height: AppSpacing.space8),
        AppTextField(
          controller: _tanggalLahirController,
          label: 'Tanggal Lahir',
          icon: Icons.calendar_month,
          readOnly: true,
          onTap: _pickDate,
        ),
        const SizedBox(height: AppSpacing.space8),
        PasswordField(
          controller: _passwordController,
          label: 'Password',
        ),
        const SizedBox(height: AppSpacing.space8),
        PasswordField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          icon: Icons.lock_reset,
        ),
        const SizedBox(height: AppSpacing.space10),
        AuthSubmitButton(
          label: 'Daftar',
          loading: _isLoading,
          onPressed: _register,
        ),
        const SizedBox(height: AppSpacing.space6),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Sudah punya akun? Login',
            style: AppTextStyles.buttonSmall,
          ),
        ),
      ],
    );
  }
}
