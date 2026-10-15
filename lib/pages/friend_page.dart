import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header_bar.dart';
import '../widgets/app_pill_button.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/app_text_field.dart';
import '../widgets/empty_state_view.dart';

/// Halaman "Friend" — kerangka daftar teman. Belum tersambung ke backend,
/// sehingga untuk saat ini hanya menampilkan kolom pencarian dan empty state.
class FriendPage extends StatefulWidget {
  const FriendPage({super.key});

  @override
  State<FriendPage> createState() => _FriendPageState();
}

class _FriendPageState extends State<FriendPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onAddFriend() {
    AppSnackBar.show(context, 'Fitur teman segera hadir.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeaderBar(title: 'Friend'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: AppTextField(
              controller: _searchController,
              label: 'Search friend',
              icon: Icons.person_search,
            ),
          ),
          const Expanded(
            child: EmptyStateView(
              icon: Icons.people_outline,
              message: 'Belum ada teman.',
              caption: 'Ajakan berteman akan tampil di sini.',
            ),
          ),
        ],
      ),
      floatingActionButton: AppPillButton(
        label: 'Add Friend',
        icon: Icons.person_add_alt,
        onPressed: _onAddFriend,
      ),
    );
  }
}
