import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsService {
  ProfileSettingsService._();

  static final ProfileSettingsService instance = ProfileSettingsService._();

  static const _kNotifications = 'profile_notifications_enabled';

  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotifications) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }
}
