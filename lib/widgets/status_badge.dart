import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/quiz_status.dart';

/// Badge status room dengan warna dari [QuizStatus.palette], jadi badge ini dan
/// pil di halaman detail room tidak pernah berbeda warna untuk status yang sama.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool dense;

  const StatusBadge({super.key, required this.status, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final palette = QuizStatus.palette(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 12, vertical: dense ? 2 : 8),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: palette.border),
      ),
      child: Text(
        QuizStatus.labelOf(status),
        style: GoogleFonts.plusJakartaSans(
          color: palette.fg,
          fontSize: dense ? 10 : 12,
          fontWeight: FontWeight.w700,
          height: 1.33,
        ),
      ),
    );
  }
}
