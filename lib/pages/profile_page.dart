import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../services/active_room_service.dart';
import '../services/auth_service.dart';
import '../services/quiz_cache_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/app_primary_button.dart';
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

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
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
      appBar: const AppHeaderBar(title: 'Profile'),
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
