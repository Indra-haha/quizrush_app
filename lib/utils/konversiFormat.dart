class CalendarUtils {
  // ================= HIJRIAH =================

  static String formatHijriah(DateTime tanggal) {
    int jd = _julianDay(tanggal);

    int l = jd - 1948440 + 10632;
    int n = ((l - 1) / 10631).floor();
    l = l - 10631 * n + 354;

    int j =
        (((10985 - l) / 5316).floor()) * ((50 * l / 17719).floor()) +
        ((l / 5670).floor()) * ((43 * l / 15238).floor());

    l =
        l -
        ((30 - j) / 15).floor() * ((17719 * j) / 50).floor() -
        (j / 16).floor() * ((15238 * j) / 43).floor() +
        29;

    int bulan = ((24 * l) / 709).floor();
    int hari = l - ((709 * bulan) / 24).floor();
    int tahun = 30 * n + j - 30;

    const namaBulan = [
      'Muharram',
      'Safar',
      'Rabiul Awal',
      'Rabiul Akhir',
      'Jumadil Awal',
      'Jumadil Akhir',
      'Rajab',
      'Syaban',
      'Ramadhan',
      'Syawal',
      'Dzulqaidah',
      'Dzulhijjah',
    ];

    return '$hari ${namaBulan[bulan - 1]} $tahun H';
  }

  // ================= UMUR =================

  static Map<String, int> hitungUmur(DateTime lahir, DateTime sekarang) {
    int tahun = sekarang.year - lahir.year;
    int bulan = sekarang.month - lahir.month;
    int hari = sekarang.day - lahir.day;

    if (hari < 0) {
      bulan--;
      final hariSebelumnya = DateTime(sekarang.year, sekarang.month, 0);
      hari += hariSebelumnya.day;
    }

    if (bulan < 0) {
      tahun--;
      bulan += 12;
    }

    final totalDetik = sekarang.difference(lahir).inSeconds;

    final jam = (totalDetik ~/ 3600) % 24;
    final menit = (totalDetik ~/ 60) % 60;
    final detik = totalDetik % 60;

    return {
      'tahun': tahun,
      'bulan': bulan,
      'hari': hari,
      'jam': jam,
      'menit': menit,
      'detik': detik,
    };
  }

  // ================= WETON =================

  static String wetonDari(DateTime tanggal) {
    const hari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    const pasaran = ['Legi', 'Pahing', 'Pon', 'Wage', 'Kliwon'];

    final namaHari = hari[tanggal.weekday - 1];

    // 1 Januari 1970 = Kamis Legi
    final acuan = DateTime(1970, 1, 1);
    final selisih = tanggal.difference(acuan).inDays;

    final indeksPasaran = (selisih + 4) % 5;
    final namaPasaran =
        pasaran[indeksPasaran < 0 ? indeksPasaran + 5 : indeksPasaran];

    return '$namaHari $namaPasaran';
  }

  // ================= SAKA BALI =================

  static String formatSakaBali(DateTime tanggal) {
    // Pendekatan sederhana berdasarkan tahun Masehi.
    final tahunSaka = tanggal.year - 78;

    return '${tanggal.day}/${tanggal.month}/${tanggal.year}\n'
        'Tahun Saka Bali: $tahunSaka';
  }

  // ================= JULIAN DAY =================

  static int _julianDay(DateTime tanggal) {
    int tahun = tanggal.year;
    int bulan = tanggal.month;
    int hari = tanggal.day;

    if (bulan <= 2) {
      tahun--;
      bulan += 12;
    }

    final a = (tahun / 100).floor();
    final b = 2 - a + (a / 4).floor();

    return (365.25 * (tahun + 4716)).floor() +
        (30.6001 * (bulan + 1)).floor() +
        hari +
        b -
        1524;
  }
}
