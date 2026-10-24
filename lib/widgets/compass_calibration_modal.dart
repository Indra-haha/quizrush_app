import 'dart:async';

import 'package:flutter/material.dart';

import '../services/compass_calibration_service.dart';
import '../theme/app_theme.dart';

class CompassCalibrationModal extends StatefulWidget {
  const CompassCalibrationModal({super.key});

  @override
  State<CompassCalibrationModal> createState() => _CompassCalibrationModalState();
}

class _CompassCalibrationModalState extends State<CompassCalibrationModal> {
  final _service = CompassCalibrationService.instance;
  StreamSubscription<CompassReading>? _sub;
  CompassDirection _direction = CompassDirection.center;
  double _deltaX = 0;
  double _deltaY = 0;
  bool _calibrating = false;
  bool _hasCalibration = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final cal = await _service.load();
    if (!mounted) return;
    setState(() { _hasCalibration = cal != null; });
    _service.start();
    _sub = _service.readings.listen((reading) {
      if (!mounted) return;
      setState(() {
        _direction = reading.direction;
        _deltaX = reading.deltaX;
        _deltaY = reading.deltaY;
      });
    });
  }

  Future<void> _calibrate() async {
    setState(() => _calibrating = true);
    _service.stop();
    await _service.calibrate();
    if (!mounted) return;
    setState(() {
      _calibrating = false;
      _hasCalibration = true;
      _direction = CompassDirection.center;
      _deltaX = 0;
      _deltaY = 0;
    });
    _service.start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final circleSize = size.width * 0.7;
    final dotSize = 16.0;
    final maxOffset = circleSize / 2 - dotSize / 2 - 12;
    final dotX = (_deltaX / 3.0).clamp(-maxOffset, maxOffset);
    final dotY = (-_deltaY / 3.0).clamp(-maxOffset, maxOffset);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textOnPrimary.withValues(alpha: 0.95),
              border: Border.all(color: AppColors.primary, width: 2),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: Size(circleSize, circleSize), painter: _CompassCirclePainter()),
                Positioned(
                  left: circleSize / 2 + dotX - dotSize / 2,
                  top: circleSize / 2 + dotY - dotSize / 2,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 50),
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _direction == CompassDirection.center ? AppColors.primary : AppColors.accentOrange,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6)],
                    ),
                  ),
                ),
                _buildLabel(circleSize, 'U', Alignment.topCenter),
                _buildLabel(circleSize, 'T', Alignment.centerRight),
                _buildLabel(circleSize, 'S', Alignment.bottomCenter),
                _buildLabel(circleSize, 'B', Alignment.centerLeft),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: circleSize,
            child: ElevatedButton(
              onPressed: _calibrating ? null : _calibrate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(_calibrating ? 'Mengkalibrasi...' : (_hasCalibration ? 'Kalibrasi Ulang' : 'Kalibrasi'), style: AppTextStyles.labelStrong),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _direction == CompassDirection.north ? 'Arah: Utara' : _direction == CompassDirection.east ? 'Arah: Timur' : _direction == CompassDirection.south ? 'Arah: Selatan' : _direction == CompassDirection.west ? 'Arah: Barat' : _hasCalibration ? 'Titik di tengah - Miringkan HP' : 'Tekan Kalibrasi untuk mengatur titik tengah',
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(double size, String text, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: Text(text, style: AppTextStyles.heading6.copyWith(color: AppColors.textPrimary)),
      ),
    );
  }
}

class _CompassCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    final paint = Paint()..color = AppColors.primary.withValues(alpha: 0.1)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawCircle(center, radius, paint);
    final linePaint = Paint()..color = AppColors.divider..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), linePaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> showCompassCalibrationModal(BuildContext context) {
  return showDialog(context: context, barrierColor: Colors.black54, builder: (context) => const CompassCalibrationModal());
}
