import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/points_indicator.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBase,
      appBar: AppHeaderBarWithActions(
        actions: const [PointsIndicator(style: PointsIndicatorStyle.home)],
      ),
      body: _buildList(),
    );
  }

  Widget _buildList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(
        top: AppSpacing.space8,
        left: AppSpacing.space9,
        right: AppSpacing.space9,
        bottom: AppSpacing.fabClearance,
      ),
      children: [
        const Text(
          'Feedback',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          'Kami sangat menghargai masukan Anda. Silakan kirimkan saran, kritik, atau pertanyaan Anda melalui formulir di bawah ini.',
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            // Aksi ketika tombol ditekan, misalnya membuka formulir feedback
          },
          child: const Text('Kirim Feedback'),
        ),
      ],
    );
  }
}
