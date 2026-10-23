import 'package:flutter/material.dart';

/// Key global supaya aksi notifikasi bisa membuka room tanpa `BuildContext`
/// dari halaman tertentu.
class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> messengerKey =
      GlobalKey<ScaffoldMessengerState>();
}
