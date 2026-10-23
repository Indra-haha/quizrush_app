import 'package:flutter/material.dart';

import '../../helpers/format.dart';
import '../../models/region_location.dart';
import '../../models/region_ranking.dart';
import '../../services/api/api_client.dart';
import '../../services/api/location_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/points_indicator.dart';

class RankingRegionPage extends StatefulWidget {
  final bool isActive;

  const RankingRegionPage({super.key, this.isActive = true});

  @override
  State<RankingRegionPage> createState() => _RankingRegionPageState();
}

class _RankingRegionPageState extends State<RankingRegionPage> {
  static const String _placeholderRegion = 'Sukajadi, Kota Bandung, Jawa Barat';
  static const List<String> _levels = ['kecamatan', 'kota', 'provinsi'];

  LocationResult? _location;
  String _activeLevel = _levels.first;
  String _meUsername = '';
  bool _locating = false;
  bool _opened = false;

  @override
  void initState() {
    super.initState();
    _loadMe();
    _loadCached();
    if (widget.isActive) _onOpened();
  }

  @override
  void didUpdateWidget(covariant RankingRegionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _onOpened();
  }

  Future<void> _loadMe() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    final username = (user?['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) return;
    setState(() => _meUsername = username);
  }

  Future<void> _loadCached() async {
    final cached = await LocationService.instance.readCached();
    if (!mounted || cached == null) return;
    setState(() => _location = cached);
  }

  Future<void> _onOpened() async {
    if (!_opened) {
      _opened = true;
      final access = await LocationService.ensurePermission();
      if (!mounted) return;
      switch (access) {
        case LocationAccess.granted:
          break;
        case LocationAccess.serviceDisabled:
          AppSnackBar.show(
            context,
            'GPS tidak aktif. Aktifkan layanan lokasi untuk peringkat wilayah.',
          );
          return;
        case LocationAccess.deniedForever:
          await _showPermissionSettingsDialog();
          return;
        case LocationAccess.denied:
          AppSnackBar.show(context, 'Izin lokasi ditolak.');
          return;
        case LocationAccess.unavailable:
          return;
      }
    }
    await _refreshLocation(silent: _location != null);
  }

  Future<void> _showPermissionSettingsDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Izin Lokasi Diperlukan'),
        content: const Text(
          'Izinkan akses lokasi di pengaturan agar lokasi sekarang dapat '
          'ditampilkan pada peringkat wilayah.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Nanti'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              LocationService.openSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  void _applyLocation(LocationResult result) {
    setState(() {
      _location = result;
      _activeLevel = 'kecamatan';
    });
  }

  Future<void> _refreshLocation({bool silent = false}) async {
    final token = await SessionService.instance.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) return;

    if (!silent) setState(() => _locating = true);
    try {
      final result = await LocationService.instance.locate(token: token);
      if (!mounted) return;
      if (result != null) {
        _applyLocation(result);
      } else if (!silent) {
        AppSnackBar.show(
          context,
          'Lokasi tidak tersedia. Aktifkan GPS dan izin lokasi.',
        );
      }
    } on ApiException catch (e) {
      if (mounted && !silent) AppSnackBar.error(context, e.message);
    } catch (_) {
      if (mounted && !silent) {
        AppSnackBar.error(context, 'Gagal memuat lokasi wilayah.');
      }
    } finally {
      if (mounted && !silent) setState(() => _locating = false);
    }
  }

  List<RegionRankingEntry> _entriesForLevel() {
    final location = _location;
    if (location == null) return const [];
    final List<RegionLeaderboardEntry> source;
    switch (_activeLevel) {
      case 'kota':
        source = location.kota;
      case 'provinsi':
        source = location.provinsi;
      default:
        source = location.kecamatan;
    }
    return [
      for (final e in source)
        RegionRankingEntry.fromLeaderboard(
          e,
          isCurrentUser: _meUsername.isNotEmpty && e.username == _meUsername,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    final entries = _entriesForLevel();
    final hasData = location != null && entries.isNotEmpty;
    final podium = entries.length >= 3
        ? entries.sublist(0, 3)
        : const <RegionRankingEntry>[];
    final listEntries = entries.length > 3
        ? entries.sublist(3, entries.length < 10 ? entries.length : 10)
        : const <RegionRankingEntry>[];
    final meIndex = entries.indexWhere((e) => e.isCurrentUser);
    final meEntry = meIndex >= 10 ? entries[meIndex] : null;

    final regionText = location?.displayName?.trim().isNotEmpty == true
        ? location!.displayName.trim()
        : _placeholderRegion;

    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC),
      appBar: AppHeaderBarWithActions(
        actions: const [PointsIndicator()],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: ShapeDecoration(
                          color: const Color(0xFFDEE8FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9999),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: Color(0xFF111C2D),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                regionText,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF111C2D),
                                  fontSize: 12,
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.w600,
                                  height: 1.33,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _locating ? null : _refreshLocation,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: ShapeDecoration(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(9999),
                                  ),
                                  shadows: const [
                                    BoxShadow(
                                      color: Color(0x0C000000),
                                      blurRadius: 2,
                                      offset: Offset(0, 1),
                                      spreadRadius: 0,
                                    )
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_location_alt,
                                      size: 12,
                                      color: Color(0xFF4648D4),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _locating ? 'Memuat...' : 'Ubah',
                                      style: const TextStyle(
                                        color: Color(0xFF4648D4),
                                        fontSize: 12,
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontWeight: FontWeight.w600,
                                        height: 1.33,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Leaderboard Wilayah',
                        style: TextStyle(
                          color: Color(0xFF111C2D),
                          fontSize: 24,
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w700,
                          height: 1.42,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Lihat jagoan kuis di sekitarmu dan rebut posisi teratas!',
                        style: TextStyle(
                          color: Color(0xFF464554),
                          fontSize: 14,
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w400,
                          height: 1.71,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFF0F3FF),
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                    width: 2, color: Color(0xFFC7C4D7)),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TabButton(
                                  label: 'Sukajadi',
                                  selected: _activeLevel == 'kecamatan',
                                  onTap: () =>
                                      setState(() => _activeLevel = 'kecamatan'),
                                ),
                                _TabButton(
                                  label: 'Kota Bandung',
                                  selected: _activeLevel == 'kota',
                                  onTap: () =>
                                      setState(() => _activeLevel = 'kota'),
                                ),
                                _TabButton(
                                  label: 'Jawa Barat',
                                  selected: _activeLevel == 'provinsi',
                                  onTap: () =>
                                      setState(() => _activeLevel = 'provinsi'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (!hasData)
                        const _EmptyHint()
                      else ...[
                        Text(
                          'Top 3 ${_activeLevel == 'kecamatan' ? 'Sukajadi' : _activeLevel == 'kota' ? 'Kota Bandung' : 'Jawa Barat'}',
                          style: const TextStyle(
                            color: Color(0xFF6063EE),
                            fontSize: 24,
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.w700,
                            height: 1.33,
                          ),
                        ),
                        const SizedBox(height: 60),
                        SizedBox(
                          height: 300,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (podium.length > 1)
                                Expanded(
                                    child: _PodiumItem(entry: podium[1], rank: 2)),
                              if (podium.isNotEmpty)
                                Expanded(
                                    child: _PodiumItem(entry: podium[0], rank: 1)),
                              if (podium.length > 2)
                                Expanded(
                                    child: _PodiumItem(entry: podium[2], rank: 3)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Peringkat 4 – 10',
                              style: TextStyle(
                                color: Color(0xFF111C2D),
                                fontSize: 18,
                                fontFamily: 'Montserrat',
                                fontWeight: FontWeight.w700,
                                height: 1.50,
                              ),
                            ),
                            Text(
                              _activeLevel == 'kecamatan'
                                  ? 'Kec. Sukajadi'
                                  : _activeLevel == 'kota'
                                      ? 'Kota Bandung'
                                      : 'Jawa Barat',
                              style: const TextStyle(
                                color: Color(0xFF6063EE),
                                fontSize: 12,
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w700,
                                height: 1.33,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        for (final entry in listEntries) ...[
                          _RankListItem(entry: entry),
                          const SizedBox(height: 8),
                        ],
                        if (meEntry != null) ...[
                          const SizedBox(height: 8),
                          _RankListItem(entry: meEntry, isMe: true),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: ShapeDecoration(
          color: selected ? const Color(0xFF6063EE) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFF464554),
            fontSize: selected ? 14 : 13,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            height: 1.43,
          ),
        ),
      ),
    );
  }
}

class _PodiumItem extends StatelessWidget {
  final RegionRankingEntry entry;
  final int rank;

  const _PodiumItem({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;
    final avatarSize = isFirst ? 96.0 : 64.0;
    final badgeSize = isFirst ? 40.0 : 32.0;
    final podiumHeight = isFirst ? 136.0 : rank == 2 ? 104.0 : 72.0;
    final podiumColor = isFirst
        ? const Color(0xFF4648D4)
        : rank == 2
            ? const Color(0xFFD8E3FB)
            : const Color(0xFFFFDDB8);
    final ringColor = isFirst
        ? const Color(0xFFFACC15)
        : rank == 2
            ? const Color(0xFFC7C4D7)
            : const Color(0xFFA36700);
    final badgeGradient = isFirst
        ? const [Color(0xFFFFD700), Color(0xFFFFA500)]
        : rank == 2
            ? const [Color(0xFFC0C0C0), Color(0xFF808080)]
            : const [Color(0xFFCD7F32), Color(0xFF825100)];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ringColor, width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 6,
                    offset: Offset(0, 4),
                    spreadRadius: -4,
                  ),
                  BoxShadow(
                    color: Color(0x19000000),
                    blurRadius: 15,
                    offset: Offset(0, 10),
                    spreadRadius: -3,
                  )
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: Center(
                  child: Text(
                    entry.initials,
                    style: TextStyle(
                      color: const Color(0xFF4648D4),
                      fontSize: isFirst ? 28 : 18,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                width: badgeSize,
                height: badgeSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: badgeGradient),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                      spreadRadius: -2,
                    ),
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                      spreadRadius: -1,
                    )
                  ],
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isFirst ? 24 : 14,
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 90,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF111C2D),
              fontSize: isFirst ? 24 : 14,
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.w700,
              height: 1.33,
            ),
          ),
        ),
        Text(
          entry.pointsLabel.replaceAll(' Pts', ''),
          style: TextStyle(
            color: const Color(0xFF4648D4),
            fontSize: isFirst ? 18 : 12,
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            boxShadow: isFirst
                ? const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 6,
                      offset: Offset(0, 4),
                      spreadRadius: -4,
                    ),
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 15,
                      offset: Offset(0, 10),
                      spreadRadius: -3,
                    )
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}

class _RankListItem extends StatelessWidget {
  final RegionRankingEntry entry;
  final bool isMe;

  const _RankListItem({required this.entry, this.isMe = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          )
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF464554),
                fontSize: 15,
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFDEE8FF),
            ),
            child: Center(
              child: Text(
                entry.initials,
                style: const TextStyle(
                  color: Color(0xFF4648D4),
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Kamu (${entry.name})' : entry.name,
                  style: const TextStyle(
                    color: Color(0xFF111C2D),
                    fontSize: 14,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  entry.subtitle,
                  style: const TextStyle(
                    color: Color(0xFF464554),
                    fontSize: 12,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.pointsLabel.replaceAll(' Pts', ''),
                style: const TextStyle(
                  color: Color(0xFF111C2D),
                  fontSize: 14,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'PTS',
                style: TextStyle(
                  color: Color(0xFF464554),
                  fontSize: 10,
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          )
        ],
      ),
      child: Column(
        children: const [
          Icon(
            Icons.public_off_outlined,
            size: 32,
            color: Color(0xFF6B7280),
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada data peringkat wilayah.',
            style: TextStyle(
              color: Color(0xFF111C2D),
              fontSize: 14,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Aktifkan izin lokasi lalu muat ulang untuk melihat peringkat terkini di sekitarmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
