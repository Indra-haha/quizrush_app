import 'package:flutter/material.dart';

import '../../models/region_location.dart';
import '../../models/region_ranking.dart';
import '../../services/api/api_client.dart';
import '../../services/api/location_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/realtime_clock_widget.dart';
import '../../widgets/status_filter.dart';

class RankingRegionPage extends StatefulWidget {
  final bool isActive;

  const RankingRegionPage({super.key, this.isActive = true});

  @override
  State<RankingRegionPage> createState() => _RankingRegionPageState();
}

class _RankingRegionPageState extends State<RankingRegionPage> {
  static const List<String> _levels = ['kecamatan', 'kota', 'provinsi'];

  LocationResult? _location;
  String _activeLevel = _levels.first;
  String _meUsername = '';
  bool _locating = false;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadMe();
    _initLocation();
  }

  @override
  void didUpdateWidget(covariant RankingRegionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      _onOpened();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadMe() async {
    final user = await SessionService.instance.getUser();
    if (!mounted) return;
    final username = (user?['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) return;
    setState(() => _meUsername = username);
  }

  Future<void> _initLocation() async {
    final enabled = await LocationService.instance.isEnabled();
    if (!enabled) {
      if (mounted) setState(() => _location = null);
      return;
    }
    final cached = await LocationService.instance.readCached();
    if (mounted && cached != null) {
      setState(() => _location = cached);
    }
  }

  /// Membuka halaman atau berpindah tab: gunakan lokasi yang sudah tersimpan (aktif).
  /// Sekali diaktifkan, lokasi akan tetap berlaku dan TIDAK meminta izin/GPS berulang kali.
  Future<void> _onOpened() async {
    if (_location != null) return;
    await _initLocation();
  }

  Future<void> _enableLocation() async {
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
        AppSnackBar.show(context, 'Layanan lokasi tidak tersedia.');
        return;
    }

    await LocationService.instance.setEnabled(true);
    await _refreshLocation(silent: false);
  }

  Future<void> _disableLocation() async {
    await LocationService.instance.setEnabled(false);
    if (!mounted) return;
    setState(() => _location = null);
    AppSnackBar.show(context, 'Lokasi wilayah dinonaktifkan.');
  }

  Future<void> _showLocationOptions() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Material(
        color: AppColors.pureSurface,
        borderRadius: AppRadius.sheet,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space8,
            vertical: AppSpacing.space6,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: AppSizes.sheetHandleWidth,
                    height: AppSizes.sheetHandleHeight,
                    decoration: const BoxDecoration(
                      color: AppColors.primaryBorder,
                      borderRadius: AppRadius.pill,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Text(
                  'Pengaturan Lokasi Wilayah',
                  style: AppTextStyles.heading3,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  'Wilayah saat ini: ${_levelLabel('kecamatan')}, ${_levelLabel('kota')}, ${_levelLabel('provinsi')}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: AppSpacing.space6),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.my_location_rounded,
                      color: AppColors.primary,
                      size: AppIconSize.md,
                    ),
                  ),
                  title: Text(
                    'Perbarui Lokasi',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: AppFontWeight.semibold,
                    ),
                  ),
                  subtitle: Text(
                    'Ambil ulang posisi GPS terkini perangkat',
                    style: AppTextStyles.bodySmall,
                  ),
                  onTap: () => Navigator.of(context).pop('refresh'),
                ),
                const Divider(height: AppSpacing.space4),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: const BoxDecoration(
                      color: AppColors.errorSoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_off_rounded,
                      color: AppColors.error,
                      size: AppIconSize.md,
                    ),
                  ),
                  title: Text(
                    'Matikan Lokasi',
                    style: AppTextStyles.labelStrongError.copyWith(
                      fontWeight: AppFontWeight.semibold,
                    ),
                  ),
                  subtitle: Text(
                    'Nonaktifkan fitur lokasi sampai diaktifkan kembali',
                    style: AppTextStyles.bodySmall,
                  ),
                  onTap: () => Navigator.of(context).pop('disable'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!mounted) return;
    if (action == 'refresh') {
      await _refreshLocation(silent: false);
    } else if (action == 'disable') {
      await _disableLocation();
    }
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
      _activeLevel = _levels.first;
    });
    if (_pageController.hasClients) _pageController.jumpToPage(0);
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

  List<RegionRankingEntry> _entriesForLevel(String level) {
    final location = _location;
    if (location == null) return const [];
    final List<RegionLeaderboardEntry> source;
    switch (level) {
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

  String _regionLabel(String? value, String fallback) {
    final label = value?.trim() ?? '';
    return label.isEmpty ? fallback : label;
  }

  String _levelLabel(String level) {
    final metadata = _location?.metadata;
    switch (level) {
      case 'kota':
        return _regionLabel(metadata?.kotaLabel, 'Kota');
      case 'provinsi':
        return _regionLabel(metadata?.provinsiLabel, 'Provinsi');
      default:
        return _regionLabel(metadata?.kecamatanLabel, 'Kecamatan');
    }
  }

  void _selectLevel(String level) {
    final index = _levels.indexOf(level);
    if (index < 0) return;
    if (!_pageController.hasClients) {
      setState(() => _activeLevel = level);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final level = _levels[index];
    if (level == _activeLevel) return;
    setState(() => _activeLevel = level);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBase,
      appBar: AppHeaderBarWithActions(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        if (_location == null) {
          await _enableLocation();
        } else {
          await _refreshLocation(silent: false);
        }
      },
      child: _buildList(),
    );
  }

  Widget _buildList() {
    final hasLocation = _location != null;
    final regionText = hasLocation
        ? '${_levelLabel('kecamatan')}, ${_levelLabel('kota')}, ${_levelLabel('provinsi')}'
        : 'Lokasi Wilayah Dinonaktifkan';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space9,
            vertical: AppSpacing.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.space1),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space4,
                ),
                decoration: const ShapeDecoration(
                  color: AppColors.surfaceSoft,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.pill,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasLocation ? Icons.location_on : Icons.location_off,
                      size: AppIconSize.sm,
                      color: hasLocation
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Expanded(
                      child: Text(
                        regionText,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyMeta.copyWith(
                          color: hasLocation
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    GestureDetector(
                      onTap: _locating
                          ? null
                          : (hasLocation
                              ? _showLocationOptions
                              : _enableLocation),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.space3,
                          vertical: AppSpacing.space1,
                        ),
                        decoration: const ShapeDecoration(
                          color: AppColors.pureSurface,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pill,
                          ),
                          shadows: AppShadows.hairlineTight,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              hasLocation
                                  ? Icons.edit_location_alt
                                  : Icons.my_location,
                              size: AppIconSize.micro,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: AppSpacing.space1),
                            Text(
                              _locating
                                  ? 'Memuat...'
                                  : (hasLocation ? 'Ubah' : 'Aktifkan'),
                              style: AppTextStyles.bodyMeta.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Leaderboard',
                          style: AppTextStyles.rankingTitle,
                        ),
                        Text(
                          'Wilayah',
                          style: AppTextStyles.rankingTitle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: RealtimeClockWidget(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space1),
              Text(
                'Lihat jagoan kuis di sekitarmu dan rebut posisi teratas!',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.71,
                ),
              ),
              const SizedBox(height: AppSpacing.space6),
              StatusFilter<String>(
                values: const ['kecamatan', 'kota', 'provinsi'],
                selected: _activeLevel,
                onChanged: _selectLevel,
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [
              _buildLevelPage('kecamatan'),
              _buildLevelPage('kota'),
              _buildLevelPage('provinsi'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelPage(String level) {
    final entries = _entriesForLevel(level);
    final hasData = entries.isNotEmpty;
    final podium = entries.take(3).toList();
    final listEntries = entries.length > 3
        ? entries.sublist(3, entries.length > 10 ? 10 : entries.length)
        : const <RegionRankingEntry>[];
    final label = _levelLabel(level);
    final listLabel = level == 'kecamatan'
        ? 'Kec. $label'
        : level == 'kota'
        ? 'Kota $label'
        : label;

    return ListView(
      key: PageStorageKey<String>('ranking-list-$level'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space8),
      children: [
        const SizedBox(height: AppSpacing.space3),
        if (!hasData)
          _EmptyHint(
            isLocationDisabled: _location == null,
            onEnable: _enableLocation,
          )
        else ...[
          Text(
            'Top ${podium.length} $label',
            style: AppTextStyles.rankingTopHeading,
          ),
          const SizedBox(height: AppSpacing.podiumTopGap),
          SizedBox(
            height: AppSizes.podiumRowHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (podium.length > 1)
                  Expanded(child: _PodiumItem(entry: podium[1], rank: 2)),
                if (podium.isNotEmpty)
                  Expanded(child: _PodiumItem(entry: podium[0], rank: 1)),
                if (podium.length > 2)
                  Expanded(child: _PodiumItem(entry: podium[2], rank: 3)),
              ],
            ),
          ),
          if (listEntries.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  listEntries.length == 7 || entries.length >= 10
                      ? 'Peringkat 4 – 10'
                      : 'Peringkat 4 – ${3 + listEntries.length}',
                  style: AppTextStyles.rankingSectionHeading,
                ),
                Text(
                  listLabel,
                  style: AppTextStyles.labelStrongSmall.copyWith(
                    color: AppColors.brandIndigo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: RewardTheme.historyTitleGap),
            for (var i = 0; i < listEntries.length; i++) ...[
              if (i > 0) const SizedBox(height: RewardTheme.historyItemGap),
              _RankListItem(entry: listEntries[i]),
            ],
          ],
          const SizedBox(height: AppSpacing.bottomListClearance),
        ],
      ],
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
    final avatarSize = isFirst
        ? AppSizes.podiumFirstAvatar
        : AppSizes.podiumOtherAvatar;
    final badgeSize = isFirst
        ? AppSizes.podiumFirstBadge
        : AppSizes.podiumOtherBadge;
    final podiumHeight = isFirst
        ? AppSizes.podiumFirstHeight
        : rank == 2
        ? AppSizes.podiumSecondHeight
        : AppSizes.podiumThirdHeight;
    final podiumColor = isFirst
        ? AppColors.primary
        : rank == 2
        ? AppColors.quizCoverSurface
        : AppColors.heroPeach;
    final ringColor = isFirst
        ? AppColors.goldRing
        : rank == 2
        ? AppColors.silverRing
        : AppColors.bronzeRing;
    final badgeGradient = isFirst
        ? AppGradients.medalGold
        : rank == 2
        ? AppGradients.medalSilver
        : AppGradients.medalBronze;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              padding: const EdgeInsets.all(AppSpacing.space1),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: ringColor,
                  width: AppBorderWidth.heavy,
                ),
                boxShadow: AppShadows.softCard,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.pureSurface,
                ),
                child: Center(
                  child: Text(
                    entry.initials,
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.primary,
                      fontSize: isFirst ? 28 : AppFontSize.title,
                      fontWeight: AppFontWeight.bold,
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
                  gradient: badgeGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppShadows.layeredCard,
                ),
                child: Center(
                  child: Text(
                    '$rank',
                    style: AppTextStyles.labelStrong.copyWith(
                      color: AppColors.textOnPrimary,
                      fontSize: isFirst ? AppFontSize.display : AppFontSize.bodyLarge,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        SizedBox(
          width: AppSizes.podiumNameWidth,
          child: Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.display2.copyWith(
              fontSize: isFirst ? AppFontSize.display : AppFontSize.bodyLarge,
              fontWeight: AppFontWeight.bold,
              height: 1.33,
            ),
          ),
        ),
        Text(
          entry.pointsLabel.replaceAll(' Pts', ''),
          style: AppTextStyles.labelStrong.copyWith(
            color: AppColors.primary,
            fontSize: isFirst ? AppFontSize.title : AppFontSize.small,
            fontWeight: AppFontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.space2),
        Container(
          width: double.infinity,
          height: podiumHeight,
          decoration: BoxDecoration(
            color: podiumColor,
            borderRadius: AppRadius.podiumTop,
            boxShadow: isFirst ? AppShadows.softCard : null,
          ),
        ),
      ],
    );
  }
}

class _RankListItem extends StatelessWidget {
  final RegionRankingEntry entry;

  const _RankListItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    final isMe = entry.isCurrentUser;
    final name = isMe ? 'Kamu (${entry.name})' : entry.name;
    final subtitle = entry.subtitle;
    final points = '${entry.pointsLabel} Pts';

    return Container(
      width: double.infinity,
      padding: RewardTheme.historyCardPadding,
      decoration: BoxDecoration(
        color: isMe ? AppColors.fieldBackground : AppColors.surface,
        borderRadius: RewardTheme.historyCardRadius,
        boxShadow: RewardTheme.historyCardShadow,
        border: isMe
            ? Border.all(
                color: AppColors.primaryBorder,
                width: AppBorderWidth.thin,
              )
            : null,
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: RewardTheme.iconCircleSize,
                height: RewardTheme.iconCircleSize,
                decoration: BoxDecoration(
                  color: isMe
                      ? AppColors.primarySoft
                      : RewardTheme.historyIconBackground(1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    entry.initials,
                    style: AppTextStyles.labelStrong.copyWith(
                      color: isMe
                          ? AppColors.primary
                          : RewardTheme.historyIconColor(1),
                      fontSize: AppFontSize.bodyLarge,
                      fontWeight: AppFontWeight.bold,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.rewardAmountInk,
                    borderRadius: AppRadius.pill,
                    boxShadow: AppShadows.hairlineTight,
                  ),
                  child: Text(
                    '#${entry.rank}',
                    style: AppTextStyles.rankingBadge,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: RewardTheme.contentGap),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RewardTextStyles.historyItemTitle,
                ),

                const SizedBox(height: AppSpacing.space1),

                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RewardTextStyles.historyItemMeta,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.space3),

          Text(
            points,
            style: RewardTextStyles.historyAmount.copyWith(
              color: isMe ? AppColors.primary : AppColors.rewardAmountInk,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final bool isLocationDisabled;
  final VoidCallback? onEnable;

  const _EmptyHint({
    this.isLocationDisabled = false,
    this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: const ShapeDecoration(
        color: AppColors.pureSurface,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        shadows: AppShadows.navBar,
      ),
      child: Column(
        children: [
          Icon(
            isLocationDisabled
                ? Icons.location_off_outlined
                : Icons.public_off_outlined,
            size: AppIconSize.xxl,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            isLocationDisabled
                ? 'Lokasi Belum Diaktifkan'
                : 'Belum ada data peringkat wilayah.',
            style: AppTextStyles.labelStrong,
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            isLocationDisabled
                ? 'Aktifkan lokasi perangkat untuk melihat peringkat pemain di sekitarmu. Sekali aktif, akan berlaku hingga kamu matikan sendiri.'
                : 'Belum ada pemain yang terdaftar pada wilayah ini.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMuted,
              fontWeight: AppFontWeight.regular,
            ),
          ),
          if (isLocationDisabled && onEnable != null) ...[
            const SizedBox(height: AppSpacing.space4),
            ElevatedButton.icon(
              onPressed: onEnable,
              icon: const Icon(Icons.my_location_rounded, size: AppIconSize.sm),
              label: const Text('Aktifkan Lokasi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.pureSurface,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.pill,
                ),
                elevation: AppElevation.none,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space6,
                  vertical: AppSpacing.space3,
                ),
                textStyle: AppTextStyles.labelStrongSmall.copyWith(
                  color: AppColors.pureSurface,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
