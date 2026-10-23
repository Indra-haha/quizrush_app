import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quizrush/services/profile_settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notifikasi mati secara default', () async {
    SharedPreferences.setMockInitialValues({});

    expect(
      await ProfileSettingsService.instance.notificationsEnabled(),
      isFalse,
    );
  });

  test('status notifikasi tersimpan di preferensi', () async {
    SharedPreferences.setMockInitialValues({});

    await ProfileSettingsService.instance.setNotificationsEnabled(true);

    expect(
      await ProfileSettingsService.instance.notificationsEnabled(),
      isTrue,
    );
  });
}
