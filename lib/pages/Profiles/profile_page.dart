import 'package:flutter/material.dart';
import 'package:quizrush/pages/Profiles/sensor_settings.dart'
    show SensorSettingsPage;

import '../../helpers/format.dart';
import '../../helpers/password_hasher.dart';
import '../../services/active_room_service.dart';
import '../../services/api/auth_service.dart';
import '../../services/biometric_service.dart';
import '../../services/notification_service.dart';
import '../../services/points_store.dart';
import '../../services/profile_settings_service.dart';
import '../../services/profile_stats_service.dart';
import '../../services/quiz_cache_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_pill_button.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/auth_fields.dart';
import '../login_redirect.dart';
import 'feedback_page.dart';

/// Halaman profil pengguna sesuai desain kartu profil + pengaturan.
class ProfilePage extends StatefulWidget {
  final Map<String, dynamic>? user;
  final ProfileStatsService? statsService;
  final bool isActive;

  const ProfilePage({
    super.key,
    this.user,
    this.statsService,
    this.isActive = true,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _user;
  ProfileStats _stats = const ProfileStats();
  bool _loggingOut = false;
  bool _biometricEnabled = false;
  bool _biometricBusy = false;
  bool _notificationsEnabled = true;

  ProfileStatsService get _statsService =>
      widget.statsService ?? ProfileStatsService.instance;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _loadUser();
    _loadBiometricState();
    _loadNotificationState();
    if (widget.isActive && _user != null) _loadStats();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _loadStats();
  }

  Future<void> _loadUser() async {
    final user = await SessionService.instance.getUser();
    if (user != null && mounted) {
      setState(() => _user = user);
      if (widget.isActive) _loadStats();
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _statsService.load(nama: _nama);
      if (mounted) setState(() => _stats = stats);
    } catch (_) {
      // Statistik bersifat pelengkap; nilai lama dipertahankan bila gagal.
    }
  }

  Future<void> _loadNotificationState() async {
    final enabled = await ProfileSettingsService.instance
        .notificationsEnabled();
    if (!enabled) {
      if (mounted) setState(() => _notificationsEnabled = false);
      return;
    }

    final granted = await NotificationService.instance.isPermissionGranted();
    if (!mounted) return;
    setState(() => _notificationsEnabled = granted);
    if (!granted) {
      await ProfileSettingsService.instance.setNotificationsEnabled(false);
    }
  }

  Future<void> _loadBiometricState() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (mounted) setState(() => _biometricEnabled = enabled);
  }

  Future<void> _toggleNotifications(bool value) async {
    if (!value) {
      setState(() => _notificationsEnabled = false);
      await ProfileSettingsService.instance.setNotificationsEnabled(false);
      await NotificationService.instance.cancelRoomReminder();
      return;
    }

    final granted = await NotificationService.instance.requestPermission();
    if (!mounted) return;
    if (!granted) {
      setState(() => _notificationsEnabled = false);
      await ProfileSettingsService.instance.setNotificationsEnabled(false);
      if (!mounted) return;
      AppSnackBar.error(
        context,
        'Izin notifikasi ditolak. Aktifkan lewat pengaturan perangkat.',
      );
      return;
    }

    setState(() => _notificationsEnabled = true);
    await ProfileSettingsService.instance.setNotificationsEnabled(true);
    if (mounted) AppSnackBar.success(context, 'Notifikasi diaktifkan.');
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

    final ok = await biometric.authenticate(
      reason: 'Aktifkan login sidik jari',
    );
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

  Future<String?> _askPassword() {
    return showDialog<String>(
      context: context,
      builder: (_) => const _PasswordPromptDialog(),
    );
  }

  String get _nama => (_user?['nama'] as String?)?.trim() ?? '';
  String get _username => (_user?['username'] as String?)?.trim() ?? '';
  String get _kelas => (_user?['kelas'] as String?)?.trim() ?? '';

  String get _initials {
    final words = _nama.split(RegExp(r'\s+'))..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return '?';
    return words.take(2).map((w) => w[0].toUpperCase()).join();
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

  Future<void> _onSettingsPage() async {
    await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const FeedbackPage()));
  }

  void _sensorSettings(String label) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => SensorSettingsPage(title: label)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppHeaderBarWithActions(
        actions: [
          _LogoutAction(
            loggingOut: _loggingOut,
            onPressed: _loggingOut ? null : _logout,
          ),
        ],
      ),
      floatingActionButton: AppPillButton(
        label: 'Feedback',
        icon: Icons.feedback_rounded,
        onPressed: _onSettingsPage,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadStats,
      child: _buildList(context),
    );
  }

  Widget _buildList(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.space8,
        left: AppSpacing.space9,
        right: AppSpacing.space9,
        bottom: AppSpacing.fabClearance,
      ),
      children: [
        _centered(
          _ProfileHeroCard(
            nama: _nama,
            username: _username,
            kelas: _kelas,
            initials: _initials,
          ),
        ),
        const SizedBox(height: AppSpacing.space10),
        _centered(
          _StatsCard(stats: _stats, points: PointsStore.instance.points),
        ),
        const SizedBox(height: AppSpacing.space10),
        _centered(
          _SettingsCard(
            notificationsEnabled: _notificationsEnabled,
            onNotificationsChanged: _toggleNotifications,
            biometricEnabled: _biometricEnabled,
            biometricBusy: _biometricBusy,
            onBiometricChanged: _toggleBiometric,
            onAdvancedTap: () => _sensorSettings('Pengaturan Sensor'),
          ),
        ),
      ],
    );
  }

  Widget _centered(Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizes.profileCard),
        child: child,
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final String nama;
  final String username;
  final String kelas;
  final String initials;

  const _ProfileHeroCard({
    required this.nama,
    required this.username,
    required this.kelas,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: ProfileTheme.cardDecoration,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSizes.profileAvatar,
            height: AppSizes.profileAvatar,
            padding: ProfileTheme.paddingSmall,
            decoration: ProfileTheme.avatarDecoration,
            child: ClipOval(
              child: Container(
                color: ProfileTheme.avatarBackground,
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTextStyles.profileAvatarInitials,
                ),
              ),
            ),
          ),
          const SizedBox(height: ProfileTheme.gapMedium),
          SizedBox(
            width: ProfileTheme.nameWidth,
            child: Text(
              nama.isEmpty ? '-' : nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.profileName,
            ),
          ),
          if (username.isNotEmpty) ...[
            const SizedBox(height: ProfileTheme.gapTiny),
            Text(
              '@$username',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
          ],
          const SizedBox(height: ProfileTheme.gapMedium),
          Container(
            padding: ProfileTheme.pillPadding,
            decoration: ProfileTheme.pillDecoration,
            child: Text(
              kelas.isEmpty ? '—' : kelas,
              textAlign: TextAlign.center,
              style: AppTextStyles.profileLocation,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final ProfileStats stats;
  final int? points;

  const _StatsCard({required this.stats, required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ProfileTheme.statsPadding,
      decoration: ProfileTheme.cardDecoration,
      child: Row(
        children: [
          _StatTile(
            value: stats.games == null ? '—' : '${stats.games}',
            label: 'Game',
            style: AppTextStyles.profileStatValue,
          ),
          _StatTile(
            value: stats.accuracy == null ? '—' : '${stats.accuracy}%',
            label: 'Akurasi',
            style: AppTextStyles.profileStatValueAccent,
          ),
          _StatTile(
            value: points == null ? '—' : formatPoints(points!),
            label: 'Koin',
            style: AppTextStyles.profileStatValue,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final TextStyle style;

  const _StatTile({
    required this.value,
    required this.label,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: ProfileTheme.statTilePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, textAlign: TextAlign.center, style: style),
            ),
            const SizedBox(height: ProfileTheme.gapTiny),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationsChanged;
  final bool biometricEnabled;
  final bool biometricBusy;
  final ValueChanged<bool> onBiometricChanged;
  final VoidCallback onAdvancedTap;

  const _SettingsCard({
    required this.notificationsEnabled,
    required this.onNotificationsChanged,
    required this.biometricEnabled,
    required this.biometricBusy,
    required this.onBiometricChanged,
    required this.onAdvancedTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ProfileTheme.settingsPadding,
      decoration: ProfileTheme.cardDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SettingsRow(
            icon: Icons.notifications_none_rounded,
            title: 'Pengaturan Notifikasi',
            subtitle: 'Izin & pengingat room',
            trailing: _DesignToggle(
              value: notificationsEnabled,
              enabled: true,
              onChanged: onNotificationsChanged,
            ),
          ),
          const SizedBox(height: ProfileTheme.gapTiny),
          _SettingsRow(
            icon: Icons.fingerprint_rounded,
            title: 'Pengaturan Biometric',
            subtitle: 'Login dengan sidik jari',
            trailing: _DesignToggle(
              value: biometricEnabled,
              enabled: !biometricBusy,
              onChanged: onBiometricChanged,
            ),
          ),
          const SizedBox(height: ProfileTheme.gapTiny),
          _SettingsRow(
            icon: Icons.tune_rounded,
            title: 'Pengaturan Lanjut',
            subtitle: 'Peningkatan performa',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              size: ProfileTheme.iconMedium,
              color: ProfileTheme.chevronColor,
            ),
            onTap: onAdvancedTap,
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lg,
      child: Padding(
        padding: ProfileTheme.settingRowPadding,
        child: Row(
          children: [
            SizedBox(
              width: ProfileTheme.iconLarge,
              height: ProfileTheme.iconLarge,
              child: Icon(
                icon,
                size: ProfileTheme.iconMedium,
                color: ProfileTheme.settingIconColor,
              ),
            ),
            const SizedBox(width: ProfileTheme.gapMedium),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelStrong),
                  const SizedBox(height: ProfileTheme.gapTiny),
                  Text(subtitle, style: AppTextStyles.settingSubtitle),
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: ProfileTheme.settingTrailingGap),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

class _DesignToggle extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool>? onChanged;

  const _DesignToggle({
    required this.value,
    required this.enabled,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onChanged != null;

    return Semantics(
      button: true,
      enabled: interactive,
      toggled: value,
      child: Opacity(
        opacity: enabled
            ? ProfileTheme.toggleEnabledOpacity
            : ProfileTheme.toggleDisabledOpacity,
        child: GestureDetector(
          onTap: interactive ? () => onChanged!(!value) : null,
          child: AnimatedContainer(
            duration: ProfileTheme.toggleDuration,
            width: AppSizes.profileToggleWidth,
            height: AppSizes.profileToggleHeight,
            padding: ProfileTheme.paddingSmall,
            decoration: ProfileTheme.toggleDecoration(active: value),
            child: AnimatedAlign(
              duration: ProfileTheme.toggleDuration,
              curve: ProfileTheme.toggleCurve,
              alignment: value
                  ? ProfileTheme.toggleActiveAlignment
                  : ProfileTheme.toggleInactiveAlignment,
              child: Container(
                width: AppSizes.profileToggleKnob,
                height: AppSizes.profileToggleKnob,
                decoration: ProfileTheme.toggleKnobDecoration,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoutAction extends StatelessWidget {
  final bool loggingOut;
  final VoidCallback? onPressed;

  const _LogoutAction({required this.loggingOut, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Keluar',
      onPressed: loggingOut ? null : onPressed,
      icon: loggingOut
          ? const SizedBox(
              width: ProfileTheme.iconMedium,
              height: ProfileTheme.iconMedium,
              child: CircularProgressIndicator(
                strokeWidth: ProfileTheme.logoutProgressStroke,
                color: ProfileTheme.logoutColor,
              ),
            )
          : const Icon(
              Icons.logout_rounded,
              size: ProfileTheme.iconLarge,
              color: ProfileTheme.logoutColor,
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
