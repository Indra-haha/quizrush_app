import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsService {
  ProfileSettingsService._();

  static final ProfileSettingsService instance = ProfileSettingsService._();

  static const _kNotifications = 'profile_notifications_enabled';
  static const _kAccelerometerEnabled = 'profile_accelerometer_enabled';
  static const _kGyroscopeEnabled = 'profile_gyroscope_enabled';

  Future<bool> notificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kNotifications) ?? false;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, value);
  }

  Future<bool> accelerometerEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kAccelerometerEnabled) ?? true;
  }

  Future<void> setAccelerometerEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAccelerometerEnabled, value);
  }

  Future<bool> gyroscopeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kGyroscopeEnabled) ?? true;
  }

  Future<void> setGyroscopeEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kGyroscopeEnabled, value);
  }
}
