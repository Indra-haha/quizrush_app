import 'package:flutter/material.dart';

import '../../helpers/format.dart';
import '../../helpers/moneychanger.dart';
import '../../models/points.dart';
import '../../models/wallet.dart';
import '../../services/api/api_client.dart';
import '../../services/api/auth_service.dart';
import '../../services/api/points_service.dart';
import '../../services/api/wallet_service.dart';
import '../../services/points_store.dart';
import '../../services/reward_cache_service.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/status_filter.dart';
import '../../widgets/app_snackbar.dart';

/// Halaman tab "Reward" dengan dua bagian yang bisa digeser: Poin dan Saldo.
class RewardPage extends StatefulWidget {
  /// Apakah tab ini sedang aktif/dibuka. Data dimuat saat halaman dibuka,
  /// bukan saat dibuat di dalam `IndexedStack`.
  final bool isActive;

  /// Service poin yang dapat di-inject pada pengujian.
  final PointsService? service;

  /// Service dompet on-chain yang dapat di-inject pada pengujian.
  final WalletService? walletService;

  const RewardPage({
    super.key,
    this.isActive = true,
    this.service,
    this.walletService,
  });

  @override
  State<RewardPage> createState() => _RewardPageState();
}

class _RewardPageState extends State<RewardPage> {
  static const List<String> _tabs = ['Poin (Pts)', 'Saldo'];
  static const int _koinToRupiah = 10;

  final PageController _pageController = PageController();

  late String _selectedTab = _tabs.first;

  PointsService get _service => widget.service ?? PointsService.instance;
  WalletService get _walletService =>
      widget.walletService ?? WalletService.instance;

  int? _points;
  List<CoinEntry> _coins = const [];
  List<WalletHistoryItem> _walletHistory = const [];
  String? _walletError;
  String _username = '';
  bool _loading = true;
  String? _error;
  bool _opened = false;
  bool _isActionInProgress = false;
  String _selectedCurrency = 'IDR';

  @override
  void initState() {
    super.initState();
    _points = PointsStore.instance.points;
    if (widget.isActive) _onOpened();
  }

  @override
  void didUpdateWidget(covariant RewardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _onOpened();
  }

  @override
  void dispose() {
    _pointConversionController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onOpened() {
    if (_opened) return;
    _opened = true;
    _load();
  }

  Future<void> _load() async {
    // 1. Tampilkan data dari cache lokal terlebih dahulu jika ada
    final cachedPoints = await RewardCacheService.instance.readPointsDetail();
    final cachedWallet = await RewardCacheService.instance.readWallet();
    if (mounted) {
      setState(() {
        if (cachedPoints != null) {
          _points = cachedPoints.points;
          _coins = cachedPoints.history;
        }
        if (cachedWallet != null) {
          _saldoRupiah = cachedWallet.currentBalance;
          _walletHistory = cachedWallet.data;
        }
        _loading = _points == null;
        _error = null;
        _walletError = null;
      });
    }

    final token = await SessionService.instance.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sesi tidak ditemukan. Silakan masuk kembali.';
      });
      return;
    }

    var userMap = await SessionService.instance.getUser();
    var username = (userMap?['username'] as String?)?.trim() ?? '';
    if (username.isEmpty) {
      try {
        final freshUser = await AuthService.instance.checkSession(token);
        username = (freshUser['username'] as String?)?.trim() ?? '';
        if (username.isNotEmpty) {
          await SessionService.instance.saveSession(token, freshUser);
        }
      } catch (_) {}
    }
    _username = username;

    try {
      // 2. Fetch saldo poin terkini & riwayat poin dari /api/me/points
      int points = _points ?? 0;
      List<CoinEntry> coins = _coins;
      try {
        final pointsDetail = await _service.fetchPointsDetail(token: token);
        points = pointsDetail.points;
        coins = pointsDetail.history;
        PointsStore.instance.setDetail(pointsDetail);
        // Simpan ke cache lokal
        await RewardCacheService.instance.savePointsDetail(pointsDetail);
      } catch (_) {}

      // 3. Fetch saldo rupiah terkini & riwayat transaksi wallet dari /api/me/wallet
      int saldo = _saldoRupiah;
      List<WalletHistoryItem> walletHistory = _walletHistory;
      String? walletError;

      try {
        final wallet = await _walletService.fetchMyWallet(token: token);
        saldo = wallet.currentBalance;
        walletHistory = wallet.data;
        // Simpan ke cache lokal
        await RewardCacheService.instance.saveWallet(wallet);
      } on ApiException catch (e) {
        if (e.statusCode < 500) {
          walletError = e.message;
        }
      } catch (_) {}

      if (!mounted) return;
      setState(() {
        _points = points;
        _coins = coins;
        _saldoRupiah = saldo;
        _walletHistory = walletHistory;
        _walletError = walletError;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.statusCode >= 500 ? null : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  void _selectTab(String tab) {
    final index = _tabs.indexOf(tab);
    if (index < 0) return;
    if (!_pageController.hasClients) {
      setState(() => _selectedTab = tab);
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    final tab = _tabs[index];
    if (tab == _selectedTab) return;
    setState(() => _selectedTab = tab);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureSurface,
      appBar: AppHeaderBarWithActions(),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space8),
          child: StatusFilter<String>(
            values: _tabs,
            selected: _selectedTab,
            onChanged: _selectTab,
          ),
        ),
        Expanded(
          child: PageView(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            children: [_buildPointTab(), _buildSaldoTab()],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATE KONVERSI POIN DAN SALDO
  // ============================================================

  // Isi dari API saldo yang sudah ada di aplikasi.
  int _saldoRupiah = 0;

  // Controller input jumlah poin.
  final TextEditingController _pointConversionController =
      TextEditingController();

  // Hasil konversi poin menjadi rupiah.
  int _conversionResultRupiah = 0;

  int get _conversionPoints =>
      int.tryParse(_pointConversionController.text.trim()) ?? 0;

  int get _conversionRupiah => (_conversionPoints * _koinToRupiah).round();

  // ============================================================
  // TAB POIN
  // ============================================================

  Widget _buildPointTab() {
    return _buildRewardTab(isPointTab: true);
  }

  // ============================================================
  // TAB SALDO
  // ============================================================

  Widget _buildSaldoTab() {
    return _buildRewardTab(isPointTab: false);
  }

  // ============================================================
  // BUILDER UTAMA
  // ============================================================

  Widget _buildRewardTab({required bool isPointTab}) {
    if (_loading &&
        _points == null &&
        _coins.isEmpty &&
        _walletHistory.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _points == null) {
      return _buildError();
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: RewardTheme.pagePadding,
        children: [
          _buildPointHeroCard(isPointTab: isPointTab),

          const SizedBox(height: RewardTheme.sectionGap),

          _buildConversionTeaserCard(isPointTab: isPointTab),

          if (isPointTab) ...[
            const SizedBox(height: RewardTheme.sectionGap),
            _buildPointHistory(),
          ] else ...[
            const SizedBox(height: RewardTheme.sectionGap),
            _buildWalletHistory(),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.space10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),

            const SizedBox(height: AppSpacing.space8),

            FilledButton(onPressed: _load, child: const Text('Coba lagi')),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HERO CARD POIN / SALDO
  // ============================================================

  Widget _buildPointHeroCard({required bool isPointTab}) {
    final int points = _points ?? 0;
    final int saldo = _saldoRupiah;

    final String title = isPointTab ? 'TOTAL POIN QUIZRUSH' : 'TOTAL SALDO DOMPET';

    final String value = isPointTab
        ? formatPoints(points)
        : formatMoney(saldo.toDouble(), 'IDR', _selectedCurrency);

    final String unit = isPointTab ? 'PTS' : _selectedCurrency;

    final String equivalent = isPointTab
        ? 'Setara: ${formatRupiah((points * _koinToRupiah).round())}'
        : 'Setara: ${formatPoints(_koinToRupiah > 0 ? (saldo / _koinToRupiah).floor() : 0)} PTS';

    return Container(
      width: double.infinity,
      padding: RewardTheme.heroPadding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: AppGradients.rewardHero,
        borderRadius: RewardTheme.heroRadius,
        boxShadow: RewardTheme.heroShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: RewardTheme.heroOrbOverlap,
            top: RewardTheme.heroOrbOverlap,
            child: Container(
              width: RewardTheme.heroOrbSize,
              height: RewardTheme.heroOrbSize,
              decoration: const BoxDecoration(
                color: RewardTheme.heroOrbColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: RewardTextStyles.heroLabel),
              const SizedBox(height: AppSpacing.space6),
              Row(
                mainAxisAlignment: !isPointTab ? MainAxisAlignment.spaceBetween : MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: RewardTextStyles.heroValue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space4),
                  if (isPointTab)
                    Text(unit, style: RewardTextStyles.heroUnit)
                  else
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        dropdownColor: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textOnPrimary,
                          size: 20,
                        ),
                        isDense: true,
                        style: RewardTextStyles.heroLabel,
                        items: supportedCurrencies.map((code) {
                          return DropdownMenuItem<String>(
                            value: code,
                            child: Text(
                              code,
                              style: RewardTextStyles.heroLabel,
                            ),
                          );
                        }).toList(),
                        onChanged: (newCurrency) {
                          if (newCurrency == null) return;
                          setState(() {
                            _selectedCurrency = newCurrency;
                          });
                        },
                      ),
                    ),
                ],
              ),

              const SizedBox(height: AppSpacing.space6),

              Container(
                padding: RewardTheme.equivalentBadgePadding,
                decoration: const BoxDecoration(
                  color: RewardTheme.equivalentBadgeColor,
                  borderRadius: RewardTheme.equivalentBadgeRadius,
                ),
                child: Text(equivalent, style: RewardTextStyles.heroEquivalent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // KARTU KONVERSI POIN / SALDO
  // ============================================================

  Widget _buildConversionTeaserCard({required bool isPointTab}) {
    return Container(
      width: double.infinity,
      padding: RewardTheme.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.pureSurface,
        borderRadius: RewardTheme.cardRadius,
        boxShadow: RewardTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: RewardTheme.iconCircleSize,
                height: RewardTheme.iconCircleSize,
                decoration: const BoxDecoration(
                  color: AppColors.heroPeach,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPointTab
                      ? Icons.currency_exchange_rounded
                      : Icons.account_balance_wallet_rounded,
                  size: RewardTheme.iconSize,
                  color: AppColors.rewardAmountInk,
                ),
              ),

              const SizedBox(width: RewardTheme.contentGap),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPointTab
                          ? 'Tukarkan Menjadi Mata Uang!'
                          : 'Konversi Poin ke Rupiah',
                      style: RewardTextStyles.cardTitle,
                    ),

                    const SizedBox(height: AppSpacing.space1),

                    Text(
                      isPointTab
                          ? 'Tukarkan poin Anda agar mendapatkan kesempatan membuat soal lagi.'
                          : 'Masukkan jumlah poin yang ingin ditukarkan untuk melihat nilai rupiahnya.',
                      style: RewardTextStyles.cardBody,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: RewardTheme.actionGap),

          // ----------------------------------------------------
          // KONTEN KHUSUS TAB SALDO
          // ----------------------------------------------------
          if (!isPointTab) ...[
            _buildConversionInput(),

            const SizedBox(height: RewardTheme.actionGap),

            _buildConversionResult(),

            const SizedBox(height: RewardTheme.actionGap),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isActionInProgress ? null : _calculateConversion,
                child: const Text('Konversi'),
              ),
            ),

            const SizedBox(height: RewardTheme.actionGap),
          ],

          // ----------------------------------------------------
          // TOMBOL BAWAH
          // ----------------------------------------------------
          Container(
            decoration: RewardTheme.actionDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: RewardTheme.actionRadius,
                onTap: () {
                  if (isPointTab) {
                    _selectTab('Saldo');
                  } else {
                    _confirmClaimPoints(_conversionPoints);
                  }
                },
                child: Padding(
                  padding: RewardTheme.actionPadding,
                  child: Text(
                    isPointTab ? 'Konversi sekarang!' : 'Tarik saldo!',
                    textAlign: TextAlign.center,
                    style: RewardTextStyles.actionLabel,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FIELD 1: INPUT JUMLAH POIN
  // ============================================================

  Widget _buildConversionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Jumlah Poin', style: RewardTextStyles.cardTitle),

        const SizedBox(height: AppSpacing.space2),

        TextField(
          controller: _pointConversionController,
          keyboardType: TextInputType.number,
          onChanged: (_) {
            setState(() {
              _conversionResultRupiah = 0;
            });
          },
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah poin',
            suffixText: 'PTS',
            prefixIcon: const Icon(Icons.toll_rounded),
            border: OutlineInputBorder(borderRadius: RewardTheme.actionRadius),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // FIELD 2: HASIL RUPIAH
  // ============================================================

  Widget _buildConversionResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hasil Konversi', style: RewardTextStyles.cardTitle),

        const SizedBox(height: AppSpacing.space2),

        TextField(
          controller: TextEditingController(
            text: formatRupiah(_conversionResultRupiah),
          ),
          readOnly: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.payments_rounded),
            suffixText: 'IDR',
            labelText: 'Estimasi Rupiah',
            border: OutlineInputBorder(borderRadius: RewardTheme.actionRadius),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PROSES HITUNG KONVERSI
  // ============================================================

  void _calculateConversion() {
    final int points = _conversionPoints;

    if (points <= 0) {
      _showRewardError('Masukkan jumlah poin yang valid.');
      return;
    }

    if (points > (_points ?? 0)) {
      _showRewardError('Poin kamu tidak mencukupi.');
      return;
    }

    if (_koinToRupiah <= 0) {
      _showRewardError('Nilai konversi belum tersedia.');
      return;
    }

    setState(() {
      _conversionResultRupiah = _conversionRupiah;
    });
  }

  void _confirmClaimPoints(int points) {
    final rupiah = points * _koinToRupiah;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Klaim Poin ke Saldo'),
        content: Text(
          'Tukarkan ${formatPoints(points)} PTS menjadi ${formatRupiah(rupiah)} ke saldo dompet Anda?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _executeClaimPoints(points);
            },
            child: const Text('Klaim Sekarang'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeClaimPoints(int points) async {
    if (_isActionInProgress) return;

    final token = await SessionService.instance.getToken();
    if (token == null || token.isEmpty) {
      _showRewardError('Sesi tidak ditemukan. Silakan masuk kembali.');
      return;
    }

    setState(() => _isActionInProgress = true);
    final rupiah = (points * _koinToRupiah).toDouble();

    try {
      final res = await _walletService.claim(
        token: token,
        userId: _username.isNotEmpty ? _username : null,
        pointsToClaim: points,
        rupiahValue: rupiah,
      );

      if (!mounted) return;
      _showRewardSuccess(
        res.message.isNotEmpty
            ? res.message
            : 'Klaim ${formatPoints(points)} PTS berhasil!',
      );

      _pointConversionController.clear();
      setState(() {
        _conversionResultRupiah = 0;
      });

      await _load();
      await PointsStore.instance.refresh();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showRewardError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showRewardError('Gagal memproses klaim poin.');
    } finally {
      if (mounted) {
        setState(() => _isActionInProgress = false);
      }
    }
  }

  // ============================================================
  // NOTIFIKASI
  // ============================================================

  void _showRewardSuccess(String message) {
    if (!mounted) return;
    AppSnackBar.success(context, message);
  }

  void _showRewardError(String message) {
    if (!mounted) return;
    AppSnackBar.error(context, message);
  }

  // ============================================================
  // RIWAYAT POIN
  // ============================================================

  Widget _buildPointHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Riwayat Poin Kuis', style: RewardTextStyles.historyTitle),

        const SizedBox(height: RewardTheme.historyTitleGap),

        if (_coins.isEmpty)
          Container(
            padding: RewardTheme.historyCardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: RewardTheme.historyCardRadius,
              boxShadow: RewardTheme.historyCardShadow,
            ),
            child: Text(
              'Belum ada riwayat poin kuis.',
              textAlign: TextAlign.center,
              style: RewardTextStyles.historyEmpty,
            ),
          )
        else
          for (var i = 0; i < _coins.length; i++) ...[
            if (i > 0) const SizedBox(height: RewardTheme.historyItemGap),

            _buildPointHistoryCard(_coins[i]),
          ],
      ],
    );
  }

  // ============================================================
  // ITEM RIWAYAT POIN
  // ============================================================

  Widget _buildPointHistoryCard(CoinEntry coin) {
    final bool positive = coin.amount >= 0;
    final String time = relativeTime(coin.createdAt);

    final String meta = coin.roomKode.isEmpty
        ? '$time • ${coin.reasonLabel}'
        : 'Room ${formatKode(coin.roomKode)} • $time';

    final String amount =
        '${positive ? '+' : '-'}${formatPoints(coin.amount.abs())} Pts';

    return Container(
      width: double.infinity,
      padding: RewardTheme.historyCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: RewardTheme.historyCardRadius,
        boxShadow: RewardTheme.historyCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: RewardTheme.iconCircleSize,
            height: RewardTheme.iconCircleSize,
            decoration: BoxDecoration(
              color: RewardTheme.historyIconBackground(coin.amount),
              shape: BoxShape.circle,
            ),
            child: Icon(
              RewardTheme.historyIcon(coin.reason, coin.amount),
              size: RewardTheme.iconSize,
              color: RewardTheme.historyIconColor(coin.amount),
            ),
          ),

          const SizedBox(width: RewardTheme.contentGap),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.reasonLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RewardTextStyles.historyItemTitle,
                ),

                const SizedBox(height: AppSpacing.space1),

                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RewardTextStyles.historyItemMeta,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.space3),

          Text(amount, style: RewardTextStyles.historyAmount),
        ],
      ),
    );
  }

  // ============================================================
  // RIWAYAT SALDO RUPIAH
  // ============================================================

  Widget _buildWalletHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Riwayat Transaksi Saldo', style: RewardTextStyles.historyTitle),

        const SizedBox(height: RewardTheme.historyTitleGap),

        if (_walletError != null && _walletHistory.isEmpty)
          Container(
            padding: RewardTheme.historyCardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: RewardTheme.historyCardRadius,
              boxShadow: RewardTheme.historyCardShadow,
            ),
            child: Text(
              _walletError!,
              textAlign: TextAlign.center,
              style: RewardTextStyles.historyEmpty,
            ),
          )
        else if (_walletHistory.isEmpty)
          Container(
            padding: RewardTheme.historyCardPadding,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: RewardTheme.historyCardRadius,
              boxShadow: RewardTheme.historyCardShadow,
            ),
            child: Text(
              'Belum ada riwayat transaksi saldo.',
              textAlign: TextAlign.center,
              style: RewardTextStyles.historyEmpty,
            ),
          )
        else
          for (var i = 0; i < _walletHistory.length; i++) ...[
            if (i > 0) const SizedBox(height: RewardTheme.historyItemGap),

            _buildWalletHistoryCard(_walletHistory[i]),
          ],
      ],
    );
  }

  // ============================================================
  // ITEM RIWAYAT SALDO RUPIAH
  // ============================================================

  Widget _buildWalletHistoryCard(WalletHistoryItem item) {
    final bool isWithdraw = item.isWithdrawal;
    final String time = relativeTime(item.createdAt);

    final String title = isWithdraw
        ? 'Tarik Saldo Rupiah'
        : (item.pointsClaimed > 0
              ? 'Klaim Poin (${formatPoints(item.pointsClaimed)} Pts)'
              : 'Penambahan Saldo');

    final String amount = isWithdraw
        ? '-${formatRupiah(item.rupiahValue.abs().round())}'
        : '+${formatRupiah(item.rupiahValue.round())}';

    final Color iconBg = isWithdraw
        ? RewardTheme.historyIconBackground(-1)
        : RewardTheme.historyIconBackground(1);

    final Color iconColor = isWithdraw
        ? RewardTheme.historyIconColor(-1)
        : RewardTheme.historyIconColor(1);

    final IconData iconData = isWithdraw
        ? Icons.arrow_outward_rounded
        : Icons.arrow_downward_rounded;

    final String meta = item.id.isNotEmpty
        ? '$time • ${item.id.length > 18 ? "${item.id.substring(0, 18)}..." : item.id}'
        : time;

    return Container(
      width: double.infinity,
      padding: RewardTheme.historyCardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: RewardTheme.historyCardRadius,
        boxShadow: RewardTheme.historyCardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: RewardTheme.iconCircleSize,
            height: RewardTheme.iconCircleSize,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(iconData, size: RewardTheme.iconSize, color: iconColor),
          ),

          const SizedBox(width: RewardTheme.contentGap),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RewardTextStyles.historyItemTitle,
                ),

                const SizedBox(height: AppSpacing.space1),

                Text(
                  meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RewardTextStyles.historyItemMeta,
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.space3),

          Text(amount, style: RewardTextStyles.historyAmount),
        ],
      ),
    );
  }
}
