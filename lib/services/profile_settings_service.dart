import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettingsService {
  ProfileSettingsService._();

  static final ProfileSettingsService instance = ProfileSettingsService._();

  static const _kNotifications = 'profile_notifications_enabled';
  static const _kAccelerometerEnabled = 'profile_accelerometer_enabled';
  static const _kGyroscopeEnabled = 'profile_gyroscope_enabled';
  static const _kGyroBaselineX = 'profile_gyro_baseline_x';
  static const _kGyroBaselineY = 'profile_gyro_baseline_y';
  static const _kGyroBaselineZ = 'profile_gyro_baseline_z';
  static const _kGyroCalibrated = 'profile_gyro_calibrated';

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

  Future<bool> isGyroCalibrated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kGyroCalibrated) ?? false;
  }

  Future<Map<String, double>?> getGyroBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    final isCal = prefs.getBool(_kGyroCalibrated) ?? false;
    if (!isCal) return null;
    final x = prefs.getDouble(_kGyroBaselineX);
    final y = prefs.getDouble(_kGyroBaselineY);
    final z = prefs.getDouble(_kGyroBaselineZ);
    if (x == null || y == null || z == null) return null;
    return {'x': x, 'y': y, 'z': z};
  }

  Future<void> setGyroBaseline({
    required double x,
    required double y,
    required double z,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kGyroBaselineX, x);
    await prefs.setDouble(_kGyroBaselineY, y);
    await prefs.setDouble(_kGyroBaselineZ, z);
    await prefs.setBool(_kGyroCalibrated, true);
  }

  Future<void> clearGyroBaseline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kGyroBaselineX);
    await prefs.remove(_kGyroBaselineY);
    await prefs.remove(_kGyroBaselineZ);
    await prefs.setBool(_kGyroCalibrated, false);
  }
}
