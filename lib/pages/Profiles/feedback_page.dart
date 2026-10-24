import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_pill_button.dart';
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
      body: _buildBody(),
      floatingActionButton: AppPillButton(
        label: 'Feedback',
        onPressed: () => (),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => Future.delayed(const Duration(seconds: 1)),
        child: _buildList(),
    );
  }

  Widget _buildList() {}

}