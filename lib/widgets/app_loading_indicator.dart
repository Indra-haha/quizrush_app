import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double strokeWidth;
  final Color color;

  const AppLoadingIndicator({
    super.key,
    this.strokeWidth = 2,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color,
    );
  }
}