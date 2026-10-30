import 'dart:math';

import 'package:flutter/material.dart';

/// Emoji sorakan melayang naik di atas layar beserta username pengirimnya,
/// dipakai ruang tunggu untuk reaksi live antar peserta. Mengikuti pola overlay
/// `AppSnackBar`: entry disisipkan ke [Overlay] lalu dihapus sendiri setelah
/// animasi selesai.
class ReactionOverlay {
  ReactionOverlay._();

  static final _random = Random();

  /// Tampilkan [emoji] dan label pengirim [username] melayang naik.
  /// [x] = posisi horizontal (koordinat global, mis. dari titik ketukan);
  /// bila null dipilih acak.
  static void show(
    BuildContext context,
    String emoji, {
    String? username,
    double? x,
  }) {
    if (emoji.isEmpty) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Stack(
            children: [
              _FloatingReaction(
                emoji: emoji,
                username: username,
                x: x ?? _random.nextDouble(),
                onDone: () {
                  if (entry.mounted) entry.remove();
                },
              ),
            ],
          ),
        ),
      ),
    );
    overlay.insert(entry);
  }
}

class _FloatingReaction extends StatefulWidget {
  final String emoji;
  final String? username;

  /// Posisi horizontal: bila 0..1 dianggap proporsi layar, selain itu
  /// dianggap koordinat piksel global (titik ketukan).
  final double x;
  final VoidCallback onDone;

  const _FloatingReaction({
    required this.emoji,
    this.username,
    required this.x,
    required this.onDone,
  });

  @override
  State<_FloatingReaction> createState() => _FloatingReactionState();
}

class _FloatingReactionState extends State<_FloatingReaction>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onDone();
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _opacity {
    final t = _controller.value;
    if (t < 0.15) return t / 0.15;
    if (t > 0.65) return (1 - t) / 0.35;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final startY = size.height * 0.72;
    final distance = size.height * 0.32;
    final left = widget.x <= 1.0
        ? (0.08 + widget.x * 0.76) * size.width
        : (widget.x - 36).clamp(8.0, size.width - 90);

    final sender = widget.username?.trim();
    final hasSender = sender != null && sender.isNotEmpty;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(_controller.value);
        return Positioned(
          left: left,
          top: startY - distance * t,
          child: Opacity(
            opacity: _opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: 0.6 + 0.55 * t,
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(widget.emoji, style: const TextStyle(fontSize: 58)),
          if (hasSender) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                sender,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
