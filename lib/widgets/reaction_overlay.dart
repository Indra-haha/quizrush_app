import 'dart:math';

import 'package:flutter/material.dart';

/// Emoji sorakan melayang naik di atas layar, dipakai ruang tunggu untuk
/// reaksi live antar peserta. Mengikuti pola overlay `AppSnackBar`: entry
/// disisipkan ke [Overlay] lalu dihapus sendiri setelah animasi selesai.
class ReactionOverlay {
  ReactionOverlay._();

  static final _random = Random();

  /// Tampilkan [emoji] melayang naik. [x] = posisi horizontal (koordinat
  /// global, mis. dari titik ketukan); bila null dipilih acak.
  static void show(BuildContext context, String emoji, {double? x}) {
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

  /// Posisi horizontal: bila 0..1 dianggap proporsi layar, selain itu
  /// dianggap koordinat piksel global (titik ketukan).
  final double x;
  final VoidCallback onDone;

  const _FloatingReaction({
    required this.emoji,
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
      duration: const Duration(milliseconds: 1500),
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
    if (t > 0.6) return (1 - t) / 0.4;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final startY = size.height * 0.72;
    final distance = size.height * 0.3;
    final left = widget.x <= 1.0
        ? (0.08 + widget.x * 0.76) * size.width
        : (widget.x - 24).clamp(8.0, size.width - 56);

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
      child: Text(widget.emoji, style: const TextStyle(fontSize: 64)),
    );
  }
}
