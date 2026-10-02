import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppSnackBar {
  AppSnackBar._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    _entry?.remove();
    _entry = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _TopNotification(
        message: message,
        backgroundColor: backgroundColor,
        duration: duration,
        onDismissed: () {
          if (_entry == entry) {
            entry.remove();
            _entry = null;
          }
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void error(BuildContext context, String message) {
    show(context, message, backgroundColor: AppColors.error);
  }

  static void success(BuildContext context, String message) {
    show(context, message, backgroundColor: AppColors.success);
  }
}

class _TopNotification extends StatefulWidget {
  final String message;
  final Color? backgroundColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNotification({
    required this.message,
    required this.backgroundColor,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopNotification> createState() => _TopNotificationState();
}

class _TopNotificationState extends State<_TopNotification>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.addStatusListener(_onStatus);
    _controller.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      widget.onDismissed();
    }
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPadding + 12,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offset,
        child: GestureDetector(
          onTap: _dismiss,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space8,
                vertical: AppSpacing.space6,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? AppColors.textPrimary,
                borderRadius: AppRadius.md,
                boxShadow: AppShadows.floating,
              ),
              child: Text(
                widget.message,
                style: AppTextStyles.bodyMediumOnPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
