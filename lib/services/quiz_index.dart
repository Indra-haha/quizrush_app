import '../models/quiz.dart';

/// Snapshot data quiz yang tersimpan di cache lokal.
///
/// [all] adalah satu-satunya sumber kebenaran (daftar flat), sedangkan [groups]
/// hanya peta `status -> list of quizId` supaya pengelompokan tetap identik
/// dengan jawaban server tanpa perlu menyimpan ulang isi kuis per grup.
class QuizCache {
  final List<Quizes> all;
  final Map<String, List<String>> groups;
  final DateTime savedAt;

  const QuizCache({
    required this.all,
    required this.groups,
    required this.savedAt,
  });

  bool get isEmpty => all.isEmpty;
}

/// Indeks pencarian yang dibangun satu kali dari [QuizCache].
///
/// Semua operasi (filter judul, pencarian PIN, filter status) berjalan di
/// memory, jadi mengetik di kolom pencarian tidak menyentuh disk atau network.
class QuizIndex {
  final DateTime savedAt;

  final Map<String, Quizes> byId;
  final Map<String, List<Quizes>> byGroup;
  final Map<String, ({String quizId, String roomId})> byKode;
  final Map<String, String> lowerTitles;

  QuizIndex._({
    required this.savedAt,
    required this.byId,
    required this.byGroup,
    required this.byKode,
    required this.lowerTitles,
  });

  factory QuizIndex.fromCache(QuizCache cache) {
    final byId = <String, Quizes>{};
    final byGroup = <String, List<Quizes>>{};
    final byKode = <String, ({String quizId, String roomId})>{};
    final lowerTitles = <String, String>{};

    for (final quiz in cache.all) {
      byId[quiz.id] = quiz;
      lowerTitles[quiz.id] = quiz.title.trim().toLowerCase();
      for (final room in quiz.rooms) {
        final kode = room.kode.trim();
        if (kode.isEmpty) continue;
        byKode.putIfAbsent(
          kode,
          () => (quizId: quiz.id, roomId: room.id),
        );
      }
    }

    for (final entry in cache.groups.entries) {
      final quizzes = <Quizes>[];
      for (final id in entry.value) {
        final quiz = byId[id];
        if (quiz != null) quizzes.add(quiz);
      }
      byGroup[entry.key] = quizzes;
    }

    return QuizIndex._(
      savedAt: cache.savedAt,
      byId: byId,
      byGroup: byGroup,
      byKode: byKode,
      lowerTitles: lowerTitles,
    );
  }

  List<Quizes> get all => byId.values.toList();

  bool get isEmpty => byId.isEmpty;

  List<Quizes> group(String status) =>
      byGroup[status] ?? const <Quizes>[];

  Quizes? quizById(String id) => byId[id];

  /// Pencarian judul: query dicocokkan dengan awal kata pertama judul saja.
  /// Kode room sengaja tidak ikut dicocokkan di sini; pencarian PIN hanya lewat
  /// [findRoomByKode] dan hanya dipanggil saat input sudah 6 digit.
  bool matches(Quizes quiz, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return (lowerTitles[quiz.id] ?? '').startsWith(q);
  }

  List<Quizes> search(String query) {
    final all = byId.values.toList();
    final q = query.trim();
    if (q.isEmpty) return all;
    return all.where((quiz) => matches(quiz, q)).toList();
  }

  ({Quizes quiz, RoomSummary room})? findRoomByKode(String kode) {
    final hit = byKode[kode.trim()];
    if (hit == null) return null;

    final quiz = byId[hit.quizId];
    if (quiz == null) return null;

    for (final room in quiz.rooms) {
      if (room.id == hit.roomId || room.kode.trim() == kode.trim()) {
        return (quiz: quiz, room: room);
      }
    }
    return null;
  }
}
