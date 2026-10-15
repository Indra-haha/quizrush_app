import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

/// Kredensial yang disimpan untuk login biometrik.
///
/// Tidak menyimpan template sidik jari (itu milik OS), melainkan kredensial
/// login agar aplikasi bisa meminta sesi baru ke server setiap kali sidik jari
/// berhasil diverifikasi.
class BiometricCredentials {
  final String username;

  /// SHA-256 (hex) password, siap dikirim ke `POST /api/login`.
  final String passwordHash;
  final Map<String, dynamic> user;

  const BiometricCredentials({
    required this.username,
    required this.passwordHash,
    required this.user,
  });
}

/// Mengelola login biometrik (sidik jari / Face ID) dan penyimpanan kredensial.
///
/// Kredensial disimpan di secure storage (Android Keystore / iOS Keychain) dan
/// hanya dibaca setelah verifikasi biometrik berhasil. Kredensial bertahan
/// meski session login dihapus (logout) sehingga bisa login ulang kapan saja.
class BiometricService {
  BiometricService._();

  static final BiometricService instance = BiometricService._();

  static const _kEnabled = 'biometric_enabled';
  static const _kUsername = 'biometric_username';
  static const _kPasswordHash = 'biometric_password_hash';
  static const _kUser = 'biometric_user';

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Apakah perangkat memiliki hardware biometrik yang siap dipakai.
  Future<bool> isDeviceSupported() async {
    if (!_isSupportedPlatform) return false;
    try {
      return await _auth.isDeviceSupported() &&
          await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Apakah sudah ada sidik jari / Face ID yang terdaftar di perangkat.
  Future<bool> hasEnrolledBiometrics() async {
    if (!_isSupportedPlatform) return false;
    try {
      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Apakah fitur login biometrik sudah diaktifkan pengguna.
  Future<bool> isEnabled() async {
    if (!_isSupportedPlatform) return false;
    try {
      return (await _storage.read(key: _kEnabled)) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// Menampilkan prompt biometrik. Mengembalikan `true` bila verifikasi sukses.
  Future<bool> authenticate({String reason = 'Verifikasi sidik jari'}) async {
    if (!_isSupportedPlatform) return false;
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Menyimpan kredensial dan menandai fitur aktif.
  Future<void> enable(BiometricCredentials credentials) async {
    await _storage.write(key: _kUsername, value: credentials.username);
    await _storage.write(key: _kPasswordHash, value: credentials.passwordHash);
    await _storage.write(key: _kUser, value: jsonEncode(credentials.user));
    await _storage.write(key: _kEnabled, value: 'true');
  }

  /// Menyegarkan kredensial saat login manual berhasil (mis. password berubah).
  ///
  /// Hanya menulis bila fitur aktif dan username tersimpan sama, agar akun lain
  /// tidak menimpa pendaftaran sidik jari yang sudah ada.
  Future<void> updateCredentials({
    required String username,
    required String passwordHash,
    required Map<String, dynamic> user,
  }) async {
    try {
      if (!await isEnabled()) return;
      final stored = await _storage.read(key: _kUsername);
      if (stored != null && stored != username) return;
      await _storage.write(key: _kUsername, value: username);
      await _storage.write(key: _kPasswordHash, value: passwordHash);
      await _storage.write(key: _kUser, value: jsonEncode(user));
    } catch (_) {
      // Gagal menyegarkan kredensial tidak menghalangi login manual.
    }
  }

  /// Menonaktifkan fitur dan menghapus kredensial tersimpan.
  Future<void> disable() async {
    await _storage.delete(key: _kUsername);
    await _storage.delete(key: _kPasswordHash);
    await _storage.delete(key: _kUser);
    await _storage.delete(key: _kEnabled);
  }

  /// Membaca kredensial tersimpan (setelah verifikasi berhasil).
  Future<BiometricCredentials?> readCredentials() async {
    try {
      final username = await _storage.read(key: _kUsername);
      final passwordHash = await _storage.read(key: _kPasswordHash);
      final rawUser = await _storage.read(key: _kUser);
      if (username == null || passwordHash == null || rawUser == null) {
        return null;
      }
      return BiometricCredentials(
        username: username,
        passwordHash: passwordHash,
        user: jsonDecode(rawUser) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }
}
