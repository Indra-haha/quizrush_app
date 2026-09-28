import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

/// Dial hitung mundur berbentuk lingkaran. Warna berubah ke merah saat sisa
/// waktu tiga detik terakhir.
class QuizCountdownDial extends StatelessWidget {
  final int seconds;
  final int urgentSeconds;

  const QuizCountdownDial({
    super.key,
    required this.seconds,
    this.urgentSeconds = 3,
  });

  bool get _isUrgent => seconds <= urgentSeconds;

  @override
  Widget build(BuildContext context) {
    final accent = _isUrgent ? Colors.red : AppColors.primary;

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent, width: 4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$seconds',
            style: GoogleFonts.montserrat(
              color: _isUrgent ? Colors.red : AppColors.ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'DETIK',
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 10,
              fontWeight: FontWeight.w400,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
