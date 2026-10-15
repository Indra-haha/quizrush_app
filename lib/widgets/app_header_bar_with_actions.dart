import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

import 'app_header_bar.dart';

class AppHeaderBarWithActions extends AppHeaderBar {
  static const _actionSpacing = 8.0;

  final List<Widget>? actions;

  const AppHeaderBarWithActions({
    super.key,
    super.title,
    super.titleStyle,
    super.leading,
    this.actions,
    super.bottom,
  });

  @override
  List<Widget> buildTrailing() {
    final actionList = actions;
    if (actionList == null || actionList.isEmpty) return const [];

    final trailing = <Widget>[const SizedBox(width: AppSpacing.space4)];
    for (var i = 0; i < actionList.length; i++) {
      if (i > 0) trailing.add(const SizedBox(width: _actionSpacing));
      trailing.add(actionList[i]);
    }
    return trailing;
  }
}
