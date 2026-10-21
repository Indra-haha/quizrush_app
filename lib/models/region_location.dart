import '../helpers/json.dart';

/// Metadata lokasi hasil `GET /api/location` (API.md §12).
class LocationMetadata {
  final Map<String, dynamic> userLocation;
  final Map<String, String> resolvedRegions;
  final String timestamp;

  const LocationMetadata({
    required this.userLocation,
    required this.resolvedRegions,
    required this.timestamp,
  });

  factory LocationMetadata.fromJson(Map<String, dynamic> json) {
    final resolved = jsonMap(json['resolved_regions']);
    return LocationMetadata(
      userLocation: jsonMap(json['user_location']),
      resolvedRegions: {
        'kecamatan': jsonString(resolved['kecamatan']),
        'kota': jsonString(resolved['kota']),
        'provinsi': jsonString(resolved['provinsi']),
      },
      timestamp: jsonString(json['timestamp']),
    );
  }

  String get display {
    final parts = <String>[
      if (resolvedRegions['kecamatan']?.isNotEmpty == true)
        resolvedRegions['kecamatan']!,
      if (resolvedRegions['kota']?.isNotEmpty == true) resolvedRegions['kota']!,
      if (resolvedRegions['provinsi']?.isNotEmpty == true)
        resolvedRegions['provinsi']!,
    ];
    if (parts.isEmpty) return 'Kecamatan, Kota, Provinsi';
    return parts.join(', ');
  }
}

/// Entitas peringkat wilayah.
class RegionLeaderboardEntry {
  final int rank;
  final String username;
  final String nama;
  final int poin;
  final double jarakMeter;

  const RegionLeaderboardEntry({
    required this.rank,
    required this.username,
    required this.nama,
    required this.poin,
    required this.jarakMeter,
  });

  factory RegionLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return RegionLeaderboardEntry(
      rank: jsonInt(json['rank']),
      username: jsonString(json['username']),
      nama: jsonString(json['nama']),
      poin: jsonInt(json['poin']),
      jarakMeter: jsonDouble(json['jarak_meter']),
    );
  }
}

/// Hasil lengkap endpoint lokasi: grouped leaderboard wilayah.
class LocationResult {
  final LocationMetadata metadata;
  final List<RegionLeaderboardEntry> kecamatan;
  final List<RegionLeaderboardEntry> kota;
  final List<RegionLeaderboardEntry> provinsi;

  const LocationResult({
    required this.metadata,
    required this.kecamatan,
    required this.kota,
    required this.provinsi,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    final data = jsonMap(json['data']);
    return LocationResult(
      metadata: LocationMetadata.fromJson(jsonMap(json['metadata'])),
      kecamatan: jsonMapList(data['kecamatan'])
          .map(RegionLeaderboardEntry.fromJson)
          .toList(),
      kota: jsonMapList(data['kota']).map(RegionLeaderboardEntry.fromJson).toList(),
      provinsi: jsonMapList(data['provinsi'])
          .map(RegionLeaderboardEntry.fromJson)
          .toList(),
    );
  }

  List<RegionLeaderboardEntry> get activeEntries {
    // Default to kecamatan if available
    if (kecamatan.isNotEmpty) return kecamatan;
    if (kota.isNotEmpty) return kota;
    if (provinsi.isNotEmpty) return provinsi;
    return const [];
  }

  String get displayName => metadata.display;

  /// Backward compatible defaults
  static const defaultFilters = <RegionFilter>[
    RegionFilter(level: 'kecamatan', label: 'Kecamatan', active: true),
    RegionFilter(level: 'kota', label: 'Kota'),
    RegionFilter(level: 'provinsi', label: 'Provinsi'),
  ];
}

/// For backward compatibility
class RegionFilter {
  final String level;
  final String label;
  final bool active;

  const RegionFilter({
    required this.level,
    required this.label,
    this.active = false,
  });
}

/// Legacy compatibility
class RegionLocation {
  final String display;
  const RegionLocation({required this.display});
  String get displayOrFallback => display;
}
