import '../models/quiz.dart';

double totalDuration(Quizes quiz) {
  var total = 0.0;
  for (final q in quiz.questions) {
    total += q.duration;
  }
  return total;
}

String formatDuration(double totalSeconds) {
  final total = totalSeconds.round();
  if (total < 60) return '$total Detik';
  final m = total ~/ 60;
  final s = total % 60;
  if (s == 0) return '$m Menit';
  return '$m Menit $s Detik';
}

String formatQDuration(double d) {
  return d == d.roundToDouble()
      ? '${d.toInt()} Detik'
      : '${d.toStringAsFixed(1)} Detik';
}

String formatKode(String kode) {
  if (kode.length == 6) {
    return '${kode.substring(0, 3)} ${kode.substring(3)}';
  }
  return kode;
}

DateTime parseTimeOrEpoch(String raw) {
  return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

String relativeTime(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  final diff = DateTime.now().difference(date.toLocal());
  if (diff.inDays >= 1) return '${diff.inDays} Hari lalu';
  if (diff.inHours >= 1) return '${diff.inHours} Jam lalu';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} Menit lalu';
  return 'Baru saja';
}

String formatTanggalLahir(String tanggalLahir) {
  final parts = tanggalLahir.split('/');
  if (parts.length != 3) return tanggalLahir;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return tanggalLahir;
  return '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
