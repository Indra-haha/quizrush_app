import 'dart:async';

import 'package:flutter/material.dart';

import 'pages/login_page.dart';
import 'services/app_navigator.dart';
import 'services/notification_service.dart';
import 'services/room_notification_router.dart';
import 'services/room_reminder_service.dart';
import 'services/room_presence_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  NotificationService.instance.setRoomReminderTapHandler(
    () => unawaited(RoomNotificationRouter.instance.openActiveRoom()),
  );
  RoomReminderService.instance.start();
  RoomPresenceService.instance.start();
  runApp(const QuizApp());
}

class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aplikasi Quiz',
      debugShowCheckedModeBanner: false,
      navigatorKey: AppNavigator.key,
      scaffoldMessengerKey: AppNavigator.messengerKey,
      theme: AppTheme.light,
      home: const LoginPage(),
    );
  }
}
