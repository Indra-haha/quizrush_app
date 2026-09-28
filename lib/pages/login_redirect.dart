import 'package:flutter/material.dart';

import 'login_page.dart';

/// Satu-satunya tempat yang mengarahkan user kembali ke halaman login.
///
/// Sebelumnya tiap halaman punya salinan `_goToLogin()` yang identik; sekarang
/// halaman cukup memanggil [LoginRedirect.go] dan memeriksa
/// `QuizFeedResult.needsAuth` sebagai penandanya.
class LoginRedirect {
  LoginRedirect._();

  static void go(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }
}
