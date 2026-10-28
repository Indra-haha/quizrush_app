import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../helpers/format.dart';
import '../models/room.dart';

/// Kontrak notifikasi room agar [RoomReminderService] bisa diuji tanpa plugin
/// platform.
abstract interface class RoomNotificationGateway {
  Future<bool> isPermissionGranted();

  Future<void> showRoomReminder(Room room);

  Future<void> cancelRoomReminder();
}

/// Pembungkus `flutter_local_notifications` untuk izin dan pengingat room.
///
/// Notifikasi hanya dipakai saat aplikasi di background atau ketika pengguna
/// meninggalkan halaman room. Tidak ada push notification dari server.
class NotificationService implements RoomNotificationGateway {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _roomReminderId = 41001;
  static const int _roomLeaveId = 41002;
  static const int _tiltNotificationId = 41003;
  static const String _channelId = 'quizrush_room_reminder';
  static const String _leaveChannelId = 'quizrush_room_leave';
  static const String _tiltChannelId = 'quizrush_tilt_selection';
  static const String _actionOpenRoom = 'open_room';
  static const String _categoryId = 'quizrush_room_reminder_category';
  static const String _leaveCategoryId = 'quizrush_room_leave_category';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _pendingRoomTap = false;
  VoidCallback? _onRoomReminderTap;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// Inisialisasi plugin. Aman dipanggil di platform yang tidak didukung
  /// (mis. saat `flutter test` di desktop) karena akan menjadi no-op.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!_supported) return;

    try {
      final settings = InitializationSettings(
        android: const AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _categoryId,
              actions: [
                DarwinNotificationAction.plain(
                  _actionOpenRoom,
                  'Kembali ke Room',
                  options: const {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
            DarwinNotificationCategory(
              _leaveCategoryId,
              actions: [
                DarwinNotificationAction.plain(
                  _actionOpenRoom,
                  'Kembali ke Room',
                  options: const {DarwinNotificationActionOption.foreground},
                ),
              ],
            ),
          ],
        ),
      );

      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _handleResponse,
      );

      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      final response = launchDetails?.notificationResponse;
      if ((launchDetails?.didNotificationLaunchApp ?? false) &&
          (response?.payload?.isNotEmpty ?? false)) {
        _pendingRoomTap = true;
      }
    } catch (_) {
      // Plugin tidak tersedia (mis. unit test/desktop); fitur notifikasi
      // otomatis nonaktif tanpa mengganggu alur aplikasi.
    }
  }

  /// Pasang handler saat notifikasi room atau aksinya dipilih.
  void setRoomReminderTapHandler(VoidCallback? handler) {
    _onRoomReminderTap = handler;
    if (handler != null && _pendingRoomTap) {
      _pendingRoomTap = false;
      handler();
    }
  }

  /// Minta izin notifikasi. Hanya dipanggil saat pengguna menyalakan toggle.
  Future<bool> requestPermission() async {
    if (!_supported) return false;
    await initialize();

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        return granted ?? true;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> isPermissionGranted() async {
    if (!_supported) return false;
    await initialize();

    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.areNotificationsEnabled() ?? false;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      if (options == null) return false;
      return options.isEnabled || options.isProvisionalEnabled;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> showRoomReminder(Room room) async {
    if (!_supported) return;
    await initialize();

    final pin = formatKode(room.kode);
    final body = pin.isEmpty
        ? 'Ketuk untuk kembali. '
        : ''
              'Ketuk untuk kembali.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Pengingat Room',
        channelDescription:
            'Pengingat saat kamu meninggalkan room kuis yang masih aktif.',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        actions: [
          AndroidNotificationAction(
            _actionOpenRoom,
            'Kembali ke Room',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _categoryId,
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.show(
        id: _roomReminderId,
        title: 'Kamu masih di Room',
        body: body,
        notificationDetails: details,
        payload: room.kode,
      );
    } catch (_) {
      // Gagal menampilkan notifikasi tidak boleh mengganggu navigasi aplikasi.
    }
  }

  Future<void> showRoomLeaveNotification({
    required String leaverName,
    required String roomCode,
  }) async {
    if (!_supported) return;
    await initialize();

    final body = '$leaverName keluar dari ruang tunggu. Ketuk untuk kembali.';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _leaveChannelId,
        'Notifikasi Room',
        channelDescription:
            'Notifikasi saat ada pemain yang keluar dari ruang tunggu.',
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.event,
        actions: [
          AndroidNotificationAction(
            _actionOpenRoom,
            'Kembali ke Room',
            showsUserInterface: true,
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        categoryIdentifier: _leaveCategoryId,
        presentAlert: true,
        presentBanner: true,
        presentList: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.show(
        id: _roomLeaveId,
        title: 'Pemain Keluar',
        body: body,
        notificationDetails: details,
        payload: roomCode,
      );
    } catch (_) {
      // Gagal menampilkan notifikasi tidak boleh mengganggu navigasi aplikasi.
    }
  }

  Future<void> showTiltNotification({
    required String title,
    required String body,
  }) async {
    if (!_supported) return;
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _tiltChannelId,
        'Sensor Gyroscope',
        channelDescription:
            'Notifikasi pemilihan opsi jawaban dengan sensor kemiringan/gyroscope.',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBanner: true,
        presentSound: true,
      ),
    );

    try {
      await _plugin.show(
        id: _tiltNotificationId,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (_) {
      // Gagal menampilkan notifikasi tidak boleh mengganggu alur aplikasi.
    }
  }

  @override
  Future<void> cancelRoomReminder() async {
    if (!_supported) return;
    await initialize();

    try {
      await _plugin.cancel(id: _roomReminderId);
    } catch (_) {
      // Abaikan kegagalan pembatalan (mis. plugin belum siap).
    }
  }

  void _handleResponse(NotificationResponse response) {
    if (response.payload?.isNotEmpty != true) return;
    _onRoomReminderTap?.call();
  }
}
