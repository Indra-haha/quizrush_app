import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../helpers/format.dart';
import '../../models/points.dart';
import '../../services/api_client.dart';
import '../../services/points_service.dart';
import '../../services/points_store.dart';
import '../../services/session_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_header_bar_with_actions.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/error_state_view.dart';
import '../../widgets/points_indicator.dart';

/// Halaman "Saldo" koin: ringkasan saldo, kalkulator konversi, dan riwayat
/// transaksi koin.
///
/// Saldo diambil dari `GET /api/me/points` dan riwayat dari `GET /api/me/coins`
/// (API.md §11). Nilai tukar koin saat ini 1 KOIN = Rp 10.
class SaldoPage extends StatefulWidget {
  /// Apakah tab ini sedang aktif/dibuka. Data dimuat saat halaman dibuka,
  /// bukan saat dibuat di dalam `IndexedStack`.
  final bool isActive;

  /// Service yang dapat di-inject pada pengujian.
  final PointsService? service;

  const SaldoPage({super.key, this.isActive = true, this.service});

  @override
  State<SaldoPage> createState() => _SaldoPageState();
}

class _SaldoPageState extends State<SaldoPage> {
  /// Nilai tukar: 1 KOIN = Rp 10.
  static const int _koinToRupiah = 10;

  /// Perkiraan kurs rupiah per 1 unit mata uang (tanpa endpoint kurs).
  static const Map<String, ({String symbol, double rate})> _currencies = {
    'IDR': (symbol: 'Rp', rate: 1),
    'USD': (symbol: r'US$', rate: 16000),
    'MYR': (symbol: 'RM', rate: 3400),
    'SGD': (symbol: r'S$', rate: 12000),
  };

  final TextEditingController _amountController = TextEditingController(
    text: '10000',
  );

  PointsService get _service => widget.service ?? PointsService.instance;

  int? _points;
  List<CoinEntry> _coins = const [];
  bool _loading = true;
  String? _error;
  bool _opened = false;
  String _currency = 'IDR';
  String _historyFilter = 'Semua';

  @override
  void initState() {
    super.initState();
    _points = PointsStore.instance.points;
    _amountController.addListener(_onAmountChanged);
    if (widget.isActive) _onOpened();
  }

  @override
  void didUpdateWidget(covariant SaldoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) _onOpened();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    if (mounted) setState(() {});
  }

  void _onOpened() {
    if (_opened) return;
    _opened = true;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final token = await SessionService.instance.getToken();
    if (!mounted) return;
    if (token == null || token.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Sesi tidak ditemukan. Silakan masuk kembali.';
      });
      return;
    }

    try {
      final points = await _service.fetchPoints(token: token);
      final coins = await _service.fetchCoins(token: token);
      if (!mounted) return;
      PointsStore.instance.set(points);
      setState(() {
        _points = points;
        _coins = coins;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Tidak bisa memuat saldo.';
      });
    }
  }

  int get _amount {
    final digits = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digits) ?? 0;
  }

  String get _conversionLabel {
    final idr = _amount * _koinToRupiah;
    final currency = _currencies[_currency]!;
    if (_currency == 'IDR') return formatRupiah(idr);
    final value = idr / currency.rate;
    return '${currency.symbol} ${value.toStringAsFixed(2)}';
  }

  List<CoinEntry> get _filteredCoins {
    switch (_historyFilter) {
      case 'Hadiah':
        return _coins.where((c) => c.reason == 'quiz_reward').toList();
      case 'Tarik':
        return _coins.where((c) => c.amount < 0).toList();
      default:
        return _coins;
    }
  }

  void _notAvailable(String label) {
    AppSnackBar.show(context, '$label belum tersedia saat ini.');
  }

  void _setAmount(int value) {
    _amountController.text = '$value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.quizCanvas,
      appBar: const AppHeaderBarWithActions(
        title: 'Saldo',
        actions: [PointsIndicator()],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _points == null && _coins.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _points == null) {
      return ErrorStateView(message: _error!, onRetry: _load);
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space8,
          AppSpacing.space4,
          AppSpacing.space8,
          AppSpacing.scrollClearance,
        ),
        children: [
          _BalanceCard(
            points: _points,
            onAction: _notAvailable,
          ),
          const SizedBox(height: AppSpacing.space8),
          _ConversionCard(
            controller: _amountController,
            currency: _currency,
            currencies: _currencies.keys.toList(),
            maxKoin: _points ?? 0,
            amount: _amount,
            resultLabel: _conversionLabel,
            onCurrency: (value) => setState(() => _currency = value),
            onQuickAmount: _setAmount,
            onCairkan: () => _notAvailable('Cairkan saldo'),
          ),
          const SizedBox(height: AppSpacing.space8),
          _HistorySection(
            coins: _filteredCoins,
            filter: _historyFilter,
            onFilter: (value) => setState(() => _historyFilter = value),
            onExport: () => _notAvailable('Ekspor riwayat'),
          ),
        ],
      ),
    );
  }
}

/// Kartu saldo koin utama.
class _BalanceCard extends StatelessWidget {
  final int? points;
  final ValueChanged<String> onAction;

  const _BalanceCard({required this.points, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final value = points ?? 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primarySoft.withValues(alpha: 0.6),
          width: AppBorderWidth.hairline,
        ),
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
            child: Column(
              children: [
                Text(
                  'SALDO KOIN QUIZRUSH',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.metaMicro.copyWith(
                    color: AppColors.inkStrong,
                    letterSpacing: 0.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      formatPoints(value),
                      style: AppTextStyles.statValue.copyWith(
                        fontSize: AppFontSize.hero,
                        color: AppColors.indigoActionInk,
                        letterSpacing: -0.9,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space3),
                    Text(
                      'KOIN',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.inkStrong,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space6,
                    vertical: AppSpacing.space2,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.tintRoom,
                    borderRadius: AppRadius.pill,
                  ),
                  child: Text(
                    '≈ ${formatRupiah(value * _SaldoPageState._koinToRupiah)}',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMeta.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              Expanded(
                child: _PillButton(
                  label: 'Tarik Saldo',
                  icon: Icons.arrow_downward_rounded,
                  filled: true,
                  onTap: () => onAction('Tarik saldo'),
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: _PillButton(
                  label: 'Top Up',
                  icon: Icons.add_rounded,
                  filled: false,
                  onTap: () => onAction('Top up'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tombol pil (terisi atau soft) untuk aksi kartu saldo/konversi.
class _PillButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;
  final bool expand;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    this.icon,
    this.filled = true,
    this.expand = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.textOnPrimary : AppColors.indigoActionInk;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: expand ? double.infinity : null,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
        decoration: BoxDecoration(
          color: filled
              ? AppColors.indigoActionInk
              : AppColors.indigoActionSoft,
          borderRadius: AppRadius.pill,
          boxShadow: AppShadows.hairlineTight,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppIconSize.sm, color: fg),
              const SizedBox(width: AppSpacing.space2),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelStrongSmall.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kalkulator konversi koin.
class _ConversionCard extends StatelessWidget {
  final TextEditingController controller;
  final String currency;
  final List<String> currencies;
  final int maxKoin;
  final int amount;
  final String resultLabel;
  final ValueChanged<String> onCurrency;
  final ValueChanged<int> onQuickAmount;
  final VoidCallback onCairkan;

  const _ConversionCard({
    required this.controller,
    required this.currency,
    required this.currencies,
    required this.maxKoin,
    required this.amount,
    required this.resultLabel,
    required this.onCurrency,
    required this.onQuickAmount,
    required this.onCairkan,
  });

  static const List<({String label, int value})> _quickAmounts = [
    (label: '1.000', value: 1000),
    (label: '5.000', value: 5000),
    (label: '10.000', value: 10000),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space8),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primarySoft.withValues(alpha: 0.6),
          width: AppBorderWidth.hairline,
        ),
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.hairlineTight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.xxl,
                height: AppIconSize.xxl,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.indigoActionSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.toll_rounded,
                  size: AppIconSize.body,
                  color: AppColors.indigoActionInk,
                ),
              ),
              const SizedBox(width: AppSpacing.space4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Konversi Koin', style: AppTextStyles.cardTitle),
                    Text(
                      'Tukar nilai koin secara instan',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                'Live',
                style: AppTextStyles.bodyCaption.copyWith(
                  color: AppColors.inkStrong,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space6),
          Text(
            'PILIH MATA UANG',
            style: AppTextStyles.metaMicro.copyWith(
              color: AppColors.inkStrong,
              letterSpacing: 0.55,
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final code in currencies)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space4),
                    child: _CurrencyChip(
                      code: code,
                      active: code == currency,
                      onTap: () => onCurrency(code),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jumlah Koin', style: AppTextStyles.bodySmall),
              Text(
                'Maks: ${formatPoints(maxKoin)}',
                style: AppTextStyles.bodyMeta.copyWith(
                  color: AppColors.indigoActionInk,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space6),
            decoration: const BoxDecoration(
              color: AppColors.tintRoom,
              borderRadius: AppRadius.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.inkStrong,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space4),
                Text(
                  'KOIN',
                  style: AppTextStyles.metaMicro.copyWith(
                    color: AppColors.inkStrong,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final quick in _quickAmounts)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.space3),
                    child: _AmountChip(
                      label: quick.label,
                      active: amount == quick.value,
                      onTap: () => onQuickAmount(quick.value),
                    ),
                  ),
                _AmountChip(
                  label: 'Semua',
                  active: maxKoin > 0 && amount == maxKoin,
                  onTap: () => onQuickAmount(maxKoin),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space6,
              vertical: AppSpacing.space6,
            ),
            decoration: const BoxDecoration(
              color: AppColors.tintRoom,
              borderRadius: AppRadius.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hasil Konversi', style: AppTextStyles.bodyCaption),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      resultLabel,
                      style: AppTextStyles.heading6.copyWith(
                        color: AppColors.indigoActionInk,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Bebas Admin',
                      style: AppTextStyles.bodyCaption.copyWith(
                        color: AppColors.inkStrong,
                        fontWeight: AppFontWeight.semibold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text('1 KOIN = Rp 10', style: AppTextStyles.bodyCaption),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space6),
          _PillButton(
            label: 'Cairkan Saldo',
            icon: Icons.account_balance_wallet_outlined,
            expand: true,
            onTap: onCairkan,
          ),
        ],
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final String code;
  final bool active;
  final VoidCallback onTap;

  const _CurrencyChip({
    required this.code,
    required this.active,
    required this.onTap,
  });

  String get _subLabel => switch (code) {
    'IDR' => 'Rupiah',
    'USD' => 'Dollar',
    'MYR' => 'Ringgit',
    'SGD' => 'Sing\$',
    _ => code,
  };

  @override
  Widget build(BuildContext context) {
    final fg = active ? AppColors.textOnPrimary : AppColors.inkStrong;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space8,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.indigoActionInk : AppColors.tintRoom,
          borderRadius: AppRadius.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelStrongSmall.copyWith(color: fg),
            ),
            Text(
              _subLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyCaption.copyWith(
                color: active
                    ? AppColors.textOnPrimary.withValues(alpha: 0.8)
                    : AppColors.inkStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmountChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _AmountChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space6,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.indigoActionSoft : AppColors.tintRoom,
          borderRadius: AppRadius.sm,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: active ? AppColors.indigoActionInk : AppColors.inkStrong,
            fontWeight: active ? AppFontWeight.bold : AppFontWeight.regular,
          ),
        ),
      ),
    );
  }
}

/// Bagian riwayat transaksi koin.
class _HistorySection extends StatelessWidget {
  final List<CoinEntry> coins;
  final String filter;
  final ValueChanged<String> onFilter;
  final VoidCallback onExport;

  const _HistorySection({
    required this.coins,
    required this.filter,
    required this.onFilter,
    required this.onExport,
  });

  static const List<String> _filters = ['Semua', 'Hadiah', 'Tarik'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Riwayat Transaksi', style: AppTextStyles.cardTitle),
            GestureDetector(
              onTap: onExport,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Ekspor',
                    style: AppTextStyles.bodyMeta.copyWith(
                      color: AppColors.indigoActionInk,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space1),
                  const Icon(
                    Icons.ios_share,
                    size: AppIconSize.xs,
                    color: AppColors.indigoActionInk,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in _filters)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.space3),
                  child: _HistoryChip(
                    label: item,
                    active: item == filter,
                    onTap: () => onFilter(item),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        if (coins.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.space10),
            child: EmptyStateView(
              icon: Icons.toll_outlined,
              message: 'Belum ada transaksi koin.',
              caption: 'Selesaikan kuis live untuk mengumpulkan koin.',
            ),
          )
        else
          for (final coin in coins) ...[
            _TransactionCard(coin: coin),
            const SizedBox(height: AppSpacing.space4),
          ],
      ],
    );
  }
}

class _HistoryChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _HistoryChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.space7,
          vertical: AppSpacing.space2,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.indigoActionInk : AppColors.tintRoom,
          borderRadius: AppRadius.pill,
          boxShadow: active ? AppShadows.hairlineTight : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: active ? AppColors.textOnPrimary : AppColors.inkStrong,
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final CoinEntry coin;

  const _TransactionCard({required this.coin});

  IconData get _icon => switch (coin.reason) {
    'quiz_reward' => Icons.emoji_events_rounded,
    _ => Icons.toll_rounded,
  };

  String get _subtitle {
    final time = relativeTime(coin.createdAt);
    if (coin.roomKode.isEmpty) return '${coin.reasonLabel} • $time';
    return 'Room ${formatKode(coin.roomKode)} • $time';
  }

  @override
  Widget build(BuildContext context) {
    final positive = coin.amount >= 0;
    final sign = positive ? '+' : '-';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.space6),
      decoration: BoxDecoration(
        color: AppColors.textOnPrimary,
        border: Border.all(
          color: AppColors.primarySoft.withValues(alpha: 0.5),
          width: AppBorderWidth.hairline,
        ),
        borderRadius: AppRadius.sm,
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        children: [
          Container(
            width: AppIconSize.xxl + AppSpacing.space2,
            height: AppIconSize.xxl + AppSpacing.space2,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.indigoActionSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _icon,
              size: AppIconSize.body,
              color: AppColors.indigoActionInk,
            ),
          ),
          const SizedBox(width: AppSpacing.space5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coin.reasonLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: AppFontWeight.semibold,
                    fontSize: AppFontSize.body,
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(_subtitle, style: AppTextStyles.bodyCaption),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space4),
          Text(
            '$sign${formatPoints(coin.amount.abs())} KOIN',
            style: AppTextStyles.heading5.copyWith(
              fontSize: AppFontSize.medium,
              color: AppColors.inkStrong,
            ),
          ),
        ],
      ),
    );
  }
}
