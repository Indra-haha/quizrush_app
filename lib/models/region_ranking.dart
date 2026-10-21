import '../helpers/format.dart';

/// Satu baris peringkat wilayah (podium / daftar / baris user).
///
/// Data masih statis (belum ada endpoint peringkat); hanya kartu lokasi dan
/// filter wilayah yang berasal dari `POST /api/location` (API.md §12).
class RegionRankingEntry {
  final int rank;
  final String name;
  final String subtitle;
  final String initials;
  final int points;
  final String tier;
  final int? streak;
  final int? accuracy;
  final String medal;
  final bool isCurrentUser;

  const RegionRankingEntry({
    required this.rank,
    required this.name,
    required this.subtitle,
    required this.initials,
    required this.points,
    this.tier = '',
    this.streak,
    this.accuracy,
    this.medal = '',
    this.isCurrentUser = false,
  });

  String get pointsLabel => formatPoints(points);

  /// Label badge tambahan: streak diutamakan, lalu akurasi.
  String? get badge {
    if (streak != null) return '🔥 $streak Streak';
    if (accuracy != null) return '🎯 $accuracy% Akurat';
    return null;
  }
}

/// Data contoh peringkat wilayah.
class RegionRankingSample {
  RegionRankingSample._();

  /// Tiga peringkat teratas — diurutkan menurut [RegionRankingEntry.rank].
  static const podium = <RegionRankingEntry>[
    RegionRankingEntry(
      rank: 1,
      name: 'Arka Pratama',
      subtitle: 'SMA 3 Bandung',
      initials: 'AP',
      points: 14850,
      accuracy: 98,
      medal: 'Juara 1',
    ),
    RegionRankingEntry(
      rank: 2,
      name: 'Nadia Putri',
      subtitle: 'Kel. Pasteur',
      initials: 'NP',
      points: 12400,
      streak: 5,
      medal: '🥈 Perak',
    ),
    RegionRankingEntry(
      rank: 3,
      name: 'Rian Setiawan',
      subtitle: 'Kel. Sukawarna',
      initials: 'RS',
      points: 11900,
      streak: 4,
      medal: '🥉 Perunggu',
    ),
  ];

  /// Baris peringkat 4–10.
  static const followers = <RegionRankingEntry>[
    RegionRankingEntry(
      rank: 4,
      name: 'Faris Alfarisi',
      subtitle: 'Kel. Pasteur',
      initials: 'FA',
      points: 10850,
      tier: 'Master Tier',
    ),
    RegionRankingEntry(
      rank: 5,
      name: 'Siti Rahmawati',
      subtitle: 'Kel. Sukajadi',
      initials: 'SR',
      points: 10210,
      tier: 'Master Tier',
    ),
    RegionRankingEntry(
      rank: 6,
      name: 'Kevin Tan',
      subtitle: 'Kel. Cipedes',
      initials: 'KT',
      points: 9980,
      tier: 'Diamond',
    ),
    RegionRankingEntry(
      rank: 7,
      name: 'Aliyah Zahra',
      subtitle: 'Kel. Sukagalih',
      initials: 'AZ',
      points: 9720,
      tier: 'Diamond',
    ),
    RegionRankingEntry(
      rank: 8,
      name: 'Budi Santoso',
      subtitle: 'Kel. Gegerkalong',
      initials: 'BS',
      points: 9540,
      tier: 'Platinum I',
    ),
    RegionRankingEntry(
      rank: 9,
      name: 'Maya Anindita',
      subtitle: 'Kel. Cipedes',
      initials: 'MA',
      points: 9310,
      tier: 'Platinum I',
    ),
    RegionRankingEntry(
      rank: 10,
      name: 'Taufik Hidayat',
      subtitle: 'Kel. Sukagalih',
      initials: 'TH',
      points: 9300,
      tier: 'Platinum II',
    ),
  ];

  /// Baris posisi user yang login.
  static const currentUser = RegionRankingEntry(
    rank: 14,
    name: 'Dimas Arya',
    subtitle: 'Kel. Sukajadi',
    initials: 'DA',
    points: 8950,
    isCurrentUser: true,
  );
}
