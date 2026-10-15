// ====================================================================
// KALKULATOR ENGINE: Modul terpisah untuk komputasi skor & ekspresi matematika
// ====================================================================
sealed class Expr {
  const Expr();
}

class AngkaExpr extends Expr {
  const AngkaExpr(this.nilai);
  final double nilai;
}

class NegExpr extends Expr {
  const NegExpr(this.target);
  final Expr target;
}

class BinerExpr extends Expr {
  const BinerExpr(this.kiri, this.opr, this.kanan);
  final Expr kiri;
  final String opr;
  final Expr kanan;
}

class KalkulatorEngine {
  KalkulatorEngine._();

  static Expr angka(num nilai) => AngkaExpr(nilai.toDouble());
  static Expr tambah(Expr a, Expr b) => BinerExpr(a, '+', b);
  static Expr kurang(Expr a, Expr b) => BinerExpr(a, '-', b);
  static Expr kali(Expr a, Expr b) => BinerExpr(a, '×', b);
  static Expr bagi(Expr a, Expr b) => BinerExpr(a, '÷', b);
  static Expr negasi(Expr target) => NegExpr(target);

  static double? hitung(Expr expr) {
    switch (expr) {
      case AngkaExpr(:final nilai):
        return nilai;
      case NegExpr(:final target):
        final nilai = hitung(target);
        return nilai == null ? null : -nilai;
      case BinerExpr(:final kiri, :final opr, :final kanan):
        final a = hitung(kiri);
        final b = hitung(kanan);
        if (a == null || b == null) return null;
        switch (opr) {
          case '+':
            return a + b;
          case '-':
            return a - b;
          case '×':
            return a * b;
          case '÷':
            if (b == 0) return null;
            return a / b;
        }
        return null;
    }
  }

  // Method khusus untuk menghitung skor kuis berdasarkan ketepatan waktu milidetik
  static int hitungSkorWaktu({
    required bool isBenar,
    required int elapsedMs,
    required int maxDurationSec,
    required int bobotMaks,
  }) {
    // Jika jawaban salah, langsung kembalikan respon 0 poin
    if (!isBenar) return 0;

    double maxMs = maxDurationSec * 1000.0;
    double sisaMs = maxMs - elapsedMs;
    if (sisaMs < 0) sisaMs = 0;

    // Komposisi menggunakan pohon ekspresi engine: (Sisa Waktu Ms ÷ Total Durasi Ms) × Bobot Maksimal
    Expr exprSisaMs = angka(sisaMs);
    Expr exprMaxMs = angka(maxMs);
    Expr exprBobot = angka(bobotMaks.toDouble());

    Expr rasioExpr = bagi(exprSisaMs, exprMaxMs);
    Expr totalSkorExpr = kali(rasioExpr, exprBobot);

    // Evaluasi hasil perhitungan via engine
    double? hasilHitung = hitung(totalSkorExpr);
    if (hasilHitung == null) return 0;

    int finalScore = hasilHitung.round();

    // Minimal tetap mendapat 5 poin jika benar, atau 0 jika waktu habis total
    return finalScore < 5 && sisaMs > 0 ? 5 : finalScore;
  }
}
