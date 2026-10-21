/// Daftar pemain yang terhubung di dalam room.
///
/// Server hanya mengirim daftar klien yang **sudah** terhubung sebelumnya
/// pada pesan `connected` (API.md §9.1) — contoh payload-nya
/// `{"type":"connected","users":2,"names":["klien-a"]}` untuk klien kedua.
/// Karena itu setiap klien wajib menambah dirinya sendiri ke roster; tanpa
/// itu grid peserta kosong padahal badge jumlah pemain tetap terisi.
class RoomRoster {
  RoomRoster._();

  /// Gabungkan daftar nama dari server dengan nama klien sendiri.
  ///
  /// Nama kosong/spasi diabaikan, dan nama sendiri ditambahkan terakhir
  /// supaya tidak tertimpa entry server dengan nama berbeda.
  static Set<String> merge(Iterable<String> names, String self) {
    final roster = <String>{};

    for (final name in names) {
      final trimmed = name.trim();
      if (trimmed.isEmpty) continue;
      roster.add(trimmed);
    }

    final own = self.trim();
    if (own.isNotEmpty) roster.add(own);

    return roster;
  }
}
