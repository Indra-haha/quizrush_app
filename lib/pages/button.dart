import 'package:flutter/material.dart';

import '../services/points_store.dart';
import '../widgets/app_bottom_nav.dart';
import 'home_page.dart';
import 'QuizPage/quiz_page.dart';
import 'Ranking/ranking_region_page.dart';
import 'Profiles/profile_page.dart';
import 'saldo/saldo_page.dart';

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
      SaldoPage(isActive: _index == 1),
      QuizPage(user: widget.user),
      RankingRegionPage(isActive: _index == 3),
      ProfilePage(user: widget.user, isActive: _index == 4),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onSelected: (i) => setState(() => _index = i),
        items: const [
          AppBottomNavItem(label: 'Home', icon: Icons.home_rounded),
          AppBottomNavItem(label: 'Reward', icon: Icons.card_giftcard_rounded),
          AppBottomNavItem(label: 'Quiz', icon: Icons.quiz_rounded),
          AppBottomNavItem(label: 'Ranking', icon: Icons.emoji_events_rounded),
          AppBottomNavItem(label: 'Profil', icon: Icons.person_rounded),
        ],
      ),
    );
  }
}
