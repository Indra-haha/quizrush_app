import 'package:flutter/material.dart';

import '../helpers/format.dart';
import '../models/region_location.dart';
import '../models/region_ranking.dart';
import '../services/api_client.dart';
import '../services/location_service.dart';
import '../services/session_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header_bar_with_actions.dart';
import '../widgets/app_snackbar.dart';
import '../widgets/points_indicator.dart';
import '../widgets/status_filter_row.dart';

/// Halaman "Peringkat Wilayah".
///
/// Podium, daftar peringkat, dan baris user diambil dari grup wilayah
/// (`kecamatan`/`kota`/`provinsi`) respons `GET /api/location` (API.md §12)
/// memakai koordinat GPS. Baris "Kamu" ditandai dengan membandingkan
/// `username` entri terhadap sesi berjalan.
class RankingRegionPage extends StatefulWidget {
  /// Apakah tab ini sedang aktif/dibuka. Izin lokasi hanya diminta saat
  /// halaman benar-benar dibuka (bukan saat dibuat di dalam `IndexedStack`).
  final bool isActive;

  const RankingRegionPage({super.key, this.isActive = true});

  @override
  State<RankingRegionPage> createState() => _RankingRegionPageState();
}

class _RankingRegionPageState extends State<RankingRegionPage> {
  static const String _placeholderRegion = 'Kecamatan, Kota, Provinsi';
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

  /// Dipanggil saat tab Peringkat dibuka: minta izin GPS lalu ambil lokasi.
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

  /// Entri grup wilayah sesuai chip yang aktif, sudah diadaptasi ke baris UI.
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
    return Scaffold(
      backgroundColor: AppColors.quizCanvas,
      appBar: const AppHeaderBarWithActions(
        title: 'Peringkat',
        actions: [PointsIndicator()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space8,
          AppSpacing.space4,
          AppSpacing.space8,
          AppSpacing.scrollClearance,
        ),
        children: [
          _LocationCard(
            region: location?.displayName,
            placeholder: _placeholderRegion,
            locating: _locating,
            onLocate: _refreshLocation,
          ),
          const SizedBox(height: AppSpacing.space1),
          // Atribusi wajib sesuai syarat lisensi OpenStreetMap (API.md §12).
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '© OpenStreetMap contributors',
              style: AppTextStyles.metaMicro,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          StatusFilterRow(
            statuses: _levels,
            selected: _activeLevel,
            onChanged: (level) => setState(() => _activeLevel = level),
          ),
          const SizedBox(height: AppSpacing.space8),
          if (!hasData)
            const _EmptyHint()
          else ...[
            _Podium(entries: podium),
            if (podium.isNotEmpty) const SizedBox(height: AppSpacing.space8),
            if (listEntries.isNotEmpty) ...[
              _ListHeader(
                total: entries.length,
                updatedAt: location.metadata.timestamp,
              ),
              const SizedBox(height: AppSpacing.space4),
              for (final entry in listEntries) ...[
                _RankRow(entry: entry),
                const SizedBox(height: AppSpacing.space4),
              ],
            ],
            if (meEntry != null) ...[
              const _DotDivider(),
              _RankRow(entry: meEntry),
            ],
          ],
        ],
      ),
    );
  }
}

/// Kartu "Lokasi Sekarang" (warna primary) dengan tombol segarkan GPS.
class _LocationCard extends StatelessWidget {
  final String? region;
  final String placeholder;
  final bool locating;
  final VoidCallback onLocate;

  const _LocationCard({
    required this.region,
    required this.placeholder,
    required this.locating,
    required this.onLocate,
  });

  @override
  Widget build(BuildContext context) {
    final hasRegion = region != null && region!.trim().isNotEmpty;
    return Container(
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.quizCard,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -AppSpacing.space11,
            top: -AppSpacing.space12,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppColors.primarySoft.withValues(alpha: 0.30),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space6,
                    vertical: AppSpacing.space4,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.textOnPrimary,
                    borderRadius: AppRadius.pill,
                    boxShadow: AppShadows.hairlineTight,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: AppIconSize.sm,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Text(
                            'Lokasi Sekarang',
                            style: AppTextStyles.labelStrongSmall.copyWith(
                              color: AppColors.inkStrong,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space1),
                      Text(
                        hasRegion ? region! : placeholder,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMeta.copyWith(
                          color: hasRegion
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.space6),
              GestureDetector(
                onTap: locating ? null : onLocate,
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.tintIcon,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.hairlineTight,
                  ),
                  child: locating
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.space2),
                          child: CircularProgressIndicator(
                            strokeWidth: AppBorderWidth.regular,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.my_location,
                          size: AppIconSize.sm,
                          color: AppColors.primaryDark,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Podium tiga besar (urutan visual 2 - 1 - 3).
class _Podium extends StatelessWidget {
  final List<RegionRankingEntry> entries;

  const _Podium({required this.entries});

  @override
  Widget build(BuildContext context) {
    if (entries.length < 3) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumColumn(entry: entries[1])),
        Expanded(child: _PodiumColumn(entry: entries[0])),
        Expanded(child: _PodiumColumn(entry: entries[2])),
      ],
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final RegionRankingEntry entry;

  const _PodiumColumn({required this.entry});

  bool get _isChampion => entry.rank == 1;

  List<Color> get _ringColors {
    switch (entry.rank) {
      case 1:
        return const [
          AppColors.warning,
          AppColors.amberSoft,
          AppColors.warning,
        ];
      case 2:
        return [
          AppColors.info.withValues(alpha: 0.55),
          AppColors.info,
        ];
      default:
        return const [AppColors.warning, AppColors.amberInk];
    }
  }

  Color get _badgeColor {
    switch (entry.rank) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.divider;
      default:
        return AppColors.amberInk;
    }
  }

  Color get _badgeInk {
    switch (entry.rank) {
      case 1:
        return AppColors.amberInk;
      case 2:
        return AppColors.textSecondary;
      default:
        return AppColors.amberSoft;
    }
  }

  double get _avatarSize => _isChampion ? 80 : 64;

  double get _pedestalHeight => _isChampion ? 96 : (entry.rank == 2 ? 64 : 52);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              width: _avatarSize,
              height: _avatarSize,
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _ringColors,
                ),
                shape: BoxShape.circle,
                boxShadow: AppShadows.layeredCard,
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.textOnPrimary,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  entry.initials,
                  style: (_isChampion
                          ? AppTextStyles.cardTitle
                          : AppTextStyles.labelStrong)
                      .copyWith(color: AppColors.primary),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _isChampion ? 28 : 24,
                height: _isChampion ? 28 : 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _badgeColor,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.layeredCard,
                ),
                child: Text(
                  '${entry.rank}',
                  style: AppTextStyles.labelStrongSmall.copyWith(
                    color: _badgeInk,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space6),
        Text(
          entry.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: _isChampion
              ? AppTextStyles.quizGroupTitle
              : AppTextStyles.labelStrong,
        ),
        Text(
          entry.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space6,
            vertical: AppSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: _isChampion ? AppColors.indigoActionInk : AppColors.textOnPrimary,
            borderRadius: AppRadius.pill,
            boxShadow: AppShadows.hairlineTight,
          ),
          child: Text(
            entry.pointsLabel,
            style: AppTextStyles.labelStrongSmall.copyWith(
              color: _isChampion
                  ? AppColors.textOnPrimary
                  : AppColors.indigoActionInk,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        Container(
          height: _pedestalHeight,
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: AppSpacing.space4),
          decoration: BoxDecoration(
            color: _isChampion ? AppColors.indigoAction : AppColors.primarySoft,
            borderRadius: BorderRadius.vertical(top: AppRadius.md.topLeft),
            boxShadow: AppShadows.layeredCard,
          ),
          child: Text(
            entry.medal,
            style: AppTextStyles.metaMicro.copyWith(
              color: _isChampion
                  ? AppColors.textOnPrimary
                  : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  final int total;
  final String updatedAt;

  const _ListHeader({required this.total, required this.updatedAt});

  @override
  Widget build(BuildContext context) {
    final updatedLabel = updatedAt.trim().isEmpty
        ? null
        : 'Update: ${relativeTime(updatedAt)}';
    return Row(
      children: [
        Text('Peringkat Wilayah', style: AppTextStyles.quizGroupTitle),
        const SizedBox(width: AppSpacing.space4),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space4,
            vertical: AppSpacing.space1,
          ),
          decoration: const BoxDecoration(
            color: AppColors.endedTint,
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            'Top $total',
            style: AppTextStyles.metaMicro.copyWith(color: AppColors.primary),
          ),
        ),
        const Spacer(),
        if (updatedLabel != null)
          Text(updatedLabel, style: AppTextStyles.metaMicro),
      ],
    );
  }
}

/// Baris peringkat (posisi 4-10 dan baris "Kamu").
class _RankRow extends StatelessWidget {
  final RegionRankingEntry entry;

  const _RankRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    final accent = isMe ? AppColors.indigoActionInk : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primarySoft.withValues(alpha: 0.70)
            : AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        border: isMe
            ? Border.all(
                color: AppColors.indigoActionInk,
                width: AppBorderWidth.heavy,
              )
            : null,
        boxShadow: isMe ? AppShadows.hairlineTight : AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isMe ? AppColors.indigoActionInk : AppColors.tintIcon,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${entry.rank}',
              style: AppTextStyles.labelStrongSmall.copyWith(
                color: isMe ? AppColors.textOnPrimary : AppColors.inkStrong,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space6),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isMe ? AppColors.indigoActionSoft : AppColors.tintIcon,
              shape: BoxShape.circle,
              boxShadow: AppShadows.layeredCard,
            ),
            child: Text(
              entry.initials,
              style: AppTextStyles.labelStrong.copyWith(
                color: isMe ? AppColors.indigoActionInk : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.space6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMe ? 'Kamu (${entry.name})' : entry.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelStrong,
                ),
                Text(
                  entry.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Text(
            entry.pointsLabel,
            style: AppTextStyles.labelStrong.copyWith(
              color: AppColors.indigoActionInk,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titik pemisah tipis antara daftar umum dan baris "Kamu".
class _DotDivider extends StatelessWidget {
  const _DotDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.indigoActionInk.withValues(alpha: 0.30),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.space2),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.indigoActionInk.withValues(alpha: 0.45),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pesan bila lokasi belum terdeteksi atau grup wilayah masih kosong.
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: const BoxDecoration(
        color: AppColors.textOnPrimary,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.public_off_outlined,
            size: AppIconSize.lg,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Belum ada data peringkat wilayah.',
            style: AppTextStyles.labelStrong,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            'Aktifkan izin lokasi lalu muat ulang untuk melihat peringkat '
            'terkini di sekitarmu.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
