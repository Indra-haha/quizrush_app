import 'package:flutter/material.dart';

import '../services/points_store.dart';
import '../theme/app_theme.dart';
import 'home_page.dart';
import 'QuizPage/quiz_page.dart';
import 'friend_page.dart';
import 'profile_page.dart';

class MainShell extends StatefulWidget {
  final Map<String, dynamic>? user;

  const MainShell({super.key, this.user});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Sesi sudah memuat poin; tampilkan segera lalu segarkan dari server.
    PointsStore.instance.setFromUser(widget.user);
    PointsStore.instance.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(user: widget.user),
      QuizPage(user: widget.user),
      FriendPage(),
      ProfilePage(user: widget.user),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Friend',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
