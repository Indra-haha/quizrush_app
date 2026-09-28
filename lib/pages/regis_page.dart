import 'dart:async';

import 'package:flutter/material.dart';
import 'package:numerus/utils/format.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_loading_indicator.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nimController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    final nim = _nimController.text.trim();
    final kelas = _kelasController.text.trim();
    final tanggalLahir = FormatTanggalLahir(
      _tanggalLahirController.text.trim(),
    );
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (nama.isEmpty ||
        nim.isEmpty ||
        kelas.isEmpty ||
        tanggalLahir.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      AppSnackBar.error(context, "Semua field wajib diisi");
      return;
    }

    if (password != confirmPassword) {
      AppSnackBar.error(context, "Password tidak cocok");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await AuthService.instance.register(
        nama: nama,
        nim: nim,
        kelas: kelas,
        tanggalLahir: tanggalLahir,
        password: password,
      );
      if (!mounted) return;
      AppSnackBar.success(
        context,
        'Registrasi berhasil, a/n ${user.nama} (NIM ${user.nim})',
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
    _nimController.dispose();
    _kelasController.dispose();
    _tanggalLahirController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'lib/assets/icon/logo.png',
                      width: 70,
                      height: 70,
                    ),
                    const SizedBox(height: 10),

                    const Text(
                      'Registrasi Akun',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),

                    const SizedBox(height: 25),

                    AppTextField(
                      controller: _namaController,
                      label: 'Nama Lengkap',
                      icon: Icons.person,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _nimController,
                      label: 'NIM',
                      icon: Icons.badge,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _kelasController,
                      label: 'Kelas',
                      icon: Icons.class_,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _tanggalLahirController,
                      label: 'Tanggal Lahir',
                      icon: Icons.calendar_month,
                      readOnly: true,
                      onTap: _pickDate,
                    ),

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: Icons.lock,
                      obscureText: _obscurePassword,
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

                    const SizedBox(height: 16),

                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Konfirmasi Password',
                      icon: Icons.lock_reset,
                      obscureText: _obscureConfirmPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
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
                          : const Text(
                              'Daftar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),

                    const SizedBox(height: 12),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Sudah punya akun? Login',
                        style: TextStyle(color: AppColors.primary),
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
