import '../helpers/format.dart';
import 'region_location.dart';

/// Satu baris peringkat wilayah (podium / daftar / baris user).
///
/// Diadaptasi dari entri leaderboard `GET /api/location` (API.md §12) lewat
/// [RegionRankingEntry.fromLeaderboard]; field UI (inisial, medal) diturunkan
/// di sini karena tidak disediakan server.
class RegionRankingEntry {
  final int rank;
  final String name;
  final String subtitle;
  final String initials;
  final int points;
  final String medal;
  final bool isCurrentUser;

  const RegionRankingEntry({
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.points,
    this.medal = '',
    this.isCurrentUser = false,
  });

  /// Adaptasi entri leaderboard API menjadi baris UI.
  ///
  /// [isCurrentUser] diisi pemanggil dengan membandingkan [username] milik
  /// sesi berjalan (server tidak menandai user sendiri di respons).
  factory RegionRankingEntry.fromLeaderboard(
    RegionLeaderboardEntry source, {
    bool isCurrentUser = false,
  }) {
    return RegionRankingEntry(
      rank: source.rank,
      name: source.nama,
      subtitle: '@${source.username}',
      initials: _initialsOf(source.nama, source.username),
      points: source.poin,
      medal: _medalOf(source.rank),
      isCurrentUser: isCurrentUser,
    );
  }

  String get pointsLabel => formatPoints(points);

  static String _initialsOf(String name, String username) {
    final words = name.trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isNotEmpty) {
      return words.take(2).map((w) => w[0].toUpperCase()).join();
    }
    final cleaned = username.trim();
    return cleaned.isEmpty ? '?' : cleaned[0].toUpperCase();
  }

  static String _medalOf(int rank) {
    switch (rank) {
      case 1:
        return 'Juara 1';
      case 2:
        return '🥈 Perak';
      case 3:
        return '🥉 Perunggu';
      default:
        return '';
    }
  }
}
