import '../theme/app_theme.dart';
import 'package:flutter/material.dart';

class AppHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.space9,
  );
  static const _contentGap = 8.0;

  final String? title;
  final TextStyle? titleStyle;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const AppHeaderBar({
    super.key,
    this.title,
    this.titleStyle,
    this.leading,
    this.bottom,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(kToolbarHeight + bottomHeight);
  }

  /// Membangun baris judul di dalam AppBar. Widget tambahan (mis. action
  /// buttons) dapat disisipkan setelah judul oleh subclass.
  @protected
  Widget buildTitleRow(List<Widget> trailing) {
    final hasLeading = leading != null;

    // Saat ada leading (mis. icon arrow), padding kiri dihilangkan agar arrow
    // menempel di tepi layar dan title tidak terdorong terlalu jauh
    return Padding(
      padding: EdgeInsets.only(
        left: hasLeading ? AppSpacing.none : _contentPadding.left,
        right: _contentPadding.right,
      ),
      child: Row(
        children: [
          if (hasLeading) ...[leading!, const SizedBox(width: _contentGap)],
          Expanded(
            child: Text(
              title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: titleStyle,
            ),
          ),
          ...trailing,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: buildTitleRow(const []),
      bottom: bottom,
    );
  }
}
