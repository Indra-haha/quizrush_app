import '../helpers/json.dart';
import '../helpers/region_label.dart';

/// Koordinat perangkat yang di-echo server pada `metadata.user_location`
/// (API.md §12.1).
class UserLocation {
  final double latitude;
  final double longitude;

  const UserLocation({required this.latitude, required this.longitude});

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    return UserLocation(
      latitude: jsonDouble(json['latitude']),
      longitude: jsonDouble(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
  };
}

/// Metadata lokasi hasil `GET /api/location` (API.md §12).
class LocationMetadata {
  final UserLocation userLocation;

  /// Slug mentah hasil reverse geocoding, misalnya `kecamatan-depok`.
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
      userLocation: UserLocation.fromJson(jsonMap(json['user_location'])),
      resolvedRegions: {
        'kecamatan': jsonString(resolved['kecamatan']),
        'kota': jsonString(resolved['kota']),
        'provinsi': jsonString(resolved['provinsi']),
      },
      timestamp: jsonString(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_location': userLocation.toJson(),
    'resolved_regions': resolvedRegions,
    'timestamp': timestamp,
  };

  /// Label singkat tiap level wilayah untuk tab/chip.
  String get kecamatanLabel => formatRegionLabel(resolvedRegions['kecamatan']!);

  String get kotaLabel => formatRegionLabel(resolvedRegions['kota']!);

  String get provinsiLabel => formatRegionLabel(resolvedRegions['provinsi']!);

  /// Label wilayah untuk UI: slug mentah dari server dibersihkan dulu lewat
  /// [formatRegionLabel], misalnya
  /// `kecamatan-pasteur, kota-bandung, provinsi-jabar` menjadi
  /// `Pasteur, kota Bandung, provinsi Jabar`.
  String get display {
    final parts = <String>[
      if (resolvedRegions['kecamatan']?.isNotEmpty == true)
        resolvedRegions['kecamatan']!,
      if (resolvedRegions['kota']?.isNotEmpty == true) resolvedRegions['kota']!,
      if (resolvedRegions['provinsi']?.isNotEmpty == true)
        resolvedRegions['provinsi']!,
    ];
    if (parts.isEmpty) return 'Kecamatan, Kota, Provinsi';
    return formatRegionLabel(parts.join(', '));
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

  Map<String, dynamic> toJson() => {
    'rank': rank,
    'username': username,
    'nama': nama,
    'poin': poin,
    'jarak_meter': jarakMeter,
  };
}

/// Hasil lengkap endpoint lokasi: grouped leaderboard wilayah.
class LocationResult {
  final int status;
  final String message;
  final LocationMetadata metadata;
  final List<RegionLeaderboardEntry> kecamatan;
  final List<RegionLeaderboardEntry> kota;
  final List<RegionLeaderboardEntry> provinsi;

  const LocationResult({
    this.status = 200,
    this.message = '',
    required this.metadata,
    required this.kecamatan,
    required this.kota,
    required this.provinsi,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    final data = jsonMap(json['data']);
    return LocationResult(
      status: jsonInt(json['status'], 200),
      message: jsonString(json['message']),
      metadata: LocationMetadata.fromJson(jsonMap(json['metadata'])),
      kecamatan: jsonMapList(
        data['kecamatan'],
      ).map(RegionLeaderboardEntry.fromJson).toList(),
      kota: jsonMapList(
        data['kota'],
      ).map(RegionLeaderboardEntry.fromJson).toList(),
      provinsi: jsonMapList(
        data['provinsi'],
      ).map(RegionLeaderboardEntry.fromJson).toList(),
    );
  }

  /// Serialisasi utuh sesuai skema respons agar seluruh grup dan entri bisa
  /// disimpan kembali tanpa ada data yang hilang.
  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'metadata': metadata.toJson(),
    'data': {
      'kecamatan': kecamatan.map((entry) => entry.toJson()).toList(),
      'kota': kota.map((entry) => entry.toJson()).toList(),
      'provinsi': provinsi.map((entry) => entry.toJson()).toList(),
    },
  };

  List<RegionLeaderboardEntry> get activeEntries {
    // Default to kecamatan if available
    if (kecamatan.isNotEmpty) return kecamatan;
    if (kota.isNotEmpty) return kota;
    if (provinsi.isNotEmpty) return provinsi;
    return const [];
  }

  String get displayName => metadata.display;
}
